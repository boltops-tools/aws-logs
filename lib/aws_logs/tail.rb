require "json"

module AwsLogs
  class Tail < Base
    attr_reader :logger
    def initialize(options = {})
      super
      # Setting to ensure matches default CLI option
      @follow = @options[:follow].nil? ? true : @options[:follow]
      @refresh_rate = @options[:refresh_rate] || 2
      @wait_exists = @options[:wait_exists]
      @wait_exists_retries = @options[:wait_exists_retries]
      @logger = @options[:logger] || default_logger # separate logger instance for thread-safety

      @loop_count = 0
      @output = [] # for specs
      reset
      set_trap
    end

    def default_logger
      logger = ActiveSupport::Logger.new($stdout)
      # The ActiveSupport::Logger::SimpleFormatter always adds extra lines to the output,
      # unlike puts, which only adds a newline if it's needed.
      # We want the simpler puts behavior.
      logger.formatter = proc { |severity, timestamp, progname, msg|
        msg = "#{msg}\n" unless msg.end_with?("\n")
        "#{msg}"
      }
      logger.level = ENV["AWS_LOGS_LOG_LEVEL"] || :info
      logger
    end

    def data(since = "24h", quiet_not_found = false)
      since, now = Since.new(since).to_i, current_now
      resp = filter_log_events(since, now)
      resp.events
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException => e
      logger.info "WARN: #{e.class}: #{e.message}" unless quiet_not_found
      []
    end

    def reset
      @events = [] # constantly replaced with recent events
      @last_shown_event_id = nil
      @completed = nil
    end

    # The start and end time is useful to limit results and make the API fast.  We'll leverage it like so:
    #
    #     1. load all events from an initial since time
    #     2. after that load events pass that first window
    #
    # It's a sliding window of time we're using.
    #
    def run
      # We overlap the sliding window because CloudWatch logs can receive or send the logs out of order.
      # For example, a bunch of logs can all come in at the same second, but they haven't registered to CloudWatch logs
      # yet. If we don't overlap the sliding window then we'll miss the logs that were delayed in registering.
      overlap = 60 * 1000 # overlap the sliding window by a minute
      since, now = initial_since, current_now
      @wait_retries ||= 0
      until end_loop?
        refresh_events(since, now)
        display

        # @last_shown_event.timestamp changes and creates a "sliding window"
        # The overlap is a just in case buffer
        since = @last_shown_event ? @last_shown_event.timestamp - overlap : initial_since
        now = current_now

        loop_count!
        sleep @refresh_rate if @follow && !ENV["AWS_LOGS_TEST"]
      end
      # Refresh and display a final time in case the end_loop gets interrupted by stop_follow!
      refresh_events(since, now)
      display
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException => e
      if @wait_exists
        seconds = Integer(@options[:wait_exists_seconds] || 5)
        unless @@waiting_already_shown
          logger.info "Waiting for log group to exist: #{@log_group_name}"
          @@waiting_already_shown = true
        end
        sleep seconds
        @wait_retries += 1
        logger.info "Waiting #{seconds} seconds. #{@wait_retries} of #{@wait_exists_retries} retries"
        if !@wait_exists_retries || @wait_retries < @wait_exists_retries
          retry
        end
        logger.info "Giving up waiting for log group to exist"
      end
      logger.info "ERROR: #{e.class}: #{e.message}".color(:red)
      logger.info "Log group #{@log_group_name} not found."
    end
    @@waiting_already_shown = false

    # TODO: lazy Enum or else its seems stuck for long --since
    def refresh_events(start_time, end_time)
      @events = []
      next_token = :start

      # TODO: can hit throttle limit if there are lots of pages
      while next_token
        resp = filter_log_events(start_time, end_time, next_token)
        @events += resp.events
        next_token = resp.next_token
      end

      @events
    end

    def filter_log_events(start_time, end_time, next_token = nil)
      options = {
        log_group_name: @log_group_name, # required
        start_time: start_time,
        end_time: end_time
        # limit: 1000,
        # interleaved: true,
      }

      options[:log_stream_names] = @options[:log_stream_names] if @options[:log_stream_names]
      options[:log_stream_name_prefix] = @options[:log_stream_name_prefix] if @options[:log_stream_name_prefix]
      options[:filter_pattern] = @options[:filter_pattern] if @options[:filter_pattern]
      options[:next_token] = next_token if next_token != :start && !next_token.nil?

      cloudwatchlogs.filter_log_events(options)
    end

    # There can be duplicated events as events can be written to the exact same timestamp.
    # So also track the last_shown_event and prevent duplicate log lines from re-appearing.
    def display
      new_events = @events
      shown_index = new_events.find_index { |e| e.event_id == @last_shown_event&.event_id }
      if shown_index
        new_events = @events[shown_index + 1..-1] || []
      end

      new_events.each do |e|
        time = Time.at(e.timestamp / 1000).utc.to_s.color(:green) unless @options[:format] == "plain"
        line = [time, e.message].compact
        format = @options[:format] || "detailed"
        line.insert(1, e.log_stream_name.color(:purple)) if format == "detailed"

        filtered = show_if? ? show_if(e) : true
        say line.join(" ") if !@options[:silence] && filtered
      end
      @last_shown_event = @events.last
      check_follow_until!
    end

    def show_if?
      !@options[:show_if].nil?
    end

    def show_if(e)
      filter = @options[:show_if]
      case filter
      when ->(f) { f.respond_to?(:call) }
        filter.call(e)
      else
        filter # true or false
      end
    end

    # [Container] 2024/03/27 02:35:32.086024 Phase complete: BUILD State: SUCCEEDED
    def codebuild_complete?(message)
      message.starts_with?("[Container]") && message.include?("Phase complete: BUILD")
    end

    def check_follow_until!
      follow_until = @options[:follow_until]
      return unless follow_until

      messages = @events.map(&:message)
      @end_loop_signal = messages.detect { |m| m.include?(follow_until) }
    end

    def say(text)
      ENV["AWS_LOGS_TEST"] ? @output << text : logger.info(text)
    end

    def output
      @output.join("\n") + "\n"
    end

    def set_trap
      Signal.trap("INT") {
        # puts must be used here instead of logger.info or else get Thread-safe error
        puts "\nCtrl-C detected. Exiting..."
        exit # immediate exit
      }
    end

    # The stop_follow! results in a little waiting because it signals to break the polling loop.
    # Since it's in the middle of the loop process, the loop will finish the sleep 5 first.
    # So it can pause from 0-5 seconds.
    def stop_follow!
      @end_loop_signal = true
    end

    # For backwards compatibility. This is not thread-safe.
    @@global_end_loop_signal = false
    def self.stop_follow!
      logger.info "WARN: AwsLogs::Tail.stop_follow! is deprecated. Use AwsLogs::Tail#stop_follow! instead which is thread-safe."
      @@global_end_loop_signal = true
    end

    private

    def initial_since
      since = @options[:since]
      seconds = since ? Since.new(since).to_i : Since::DEFAULT
      (Time.now.to_i - seconds) * 1000 # past 10 minutes in milliseconds
    end

    def current_now
      Time.now.to_i * 1000 # now in milliseconds
    end

    def end_loop?
      return true if @@global_end_loop_signal
      return true if @end_loop_signal
      max_loop_count && @loop_count >= max_loop_count
    end

    def loop_count!
      @loop_count += 1
    end

    # Useful for specs
    def max_loop_count
      @follow ? nil : 1
    end
  end
end
