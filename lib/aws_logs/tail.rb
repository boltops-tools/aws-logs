require "json"

module AwsLogs
  class Tail
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group_name = options[:log_group_name]
      # Setting to ensure matches default CLI option
      @follow = @options[:follow] || true

      @loop_count = 0
      @output = [] # for specs
      reset
      set_trap
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
      if ENV['AWS_LOGS_NOOP']
        puts "Noop test"
        return
      end

      since, now = initial_since, current_now
      while true && !end_loop?
        refresh_events(since, now)
        display
        since, now = now, current_now
        loop_count!
        sleep 5 if @follow && !@@end_loop_signal && !ENV["AWS_LOGS_TEST"]
      end
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException => e
      puts "ERROR: #{e.class}: #{e.message}".color(:red)
      puts "Log group #{@log_group_name} not found."
    end

    def refresh_events(start_time, end_time)
      @events = []
      next_token = :start

      # TODO: can hit throttle limit if there are lots of pages
      while next_token
        options = {
          log_group_name: @log_group_name, # required
          start_time: start_time,
          end_time: end_time,
          # limit: 10,
        }
        options[:log_stream_names] = @options[:log_stream_names] if @options[:log_stream_names]
        options[:log_stream_name_prefix] = @options[:log_stream_name_prefix] if @options[:log_stream_name_prefix]
        options[:filter_pattern] = @options[:filter_pattern] if @options[:filter_pattern]
        resp = cloudwatchlogs.filter_log_events(options)

        @events += resp.events
        next_token = resp.next_token
      end

      @events
    end

    # Events canduplicated as events can be written to the exact same timestamp.
    # So also track the last_shown_event_id and prevent duplicate log lines from re-appearing.
    def display
      new_events = @events
      shown_index = new_events.find_index { |e| e.event_id == @last_shown_event_id }
      if shown_index
        new_events = @events[shown_index+1..-1] || []
      end

      new_events.each do |e|
        time = Time.at(e.timestamp/1000).utc
        line = [time.to_s.color(:green), e.message]
        format = @options[:format] || "detailed"
        line.insert(1, e.log_stream_name.color(:purple)) if format == "detailed"
        say line.join(' ')
      end
      @last_shown_event_id = @events.last&.event_id
      check_follow_until!
    end

    def check_follow_until!
      follow_until = @options[:follow_until]
      return unless follow_until

      messages = @events.map(&:message)
      if messages.detect { |m| m.include?(follow_until) }
        @@end_loop_signal = true
      end
    end

    def say(text)
      ENV["AWS_LOGS_TEST"] ? @output << text : puts(text)
    end

    def output
      @output.join("\n") + "\n"
    end

    @@end_loop_signal = false
    def set_trap
      Signal.trap("INT") {
        puts "\nCtrl-C detected. Exiting..."
        @@end_loop_signal = true  # useful to control loop
        exit # immediate exit
      }
    end

    def self.stop_follow!
      @@end_loop_signal = true
    end

  private
    def initial_since
      since = @options[:since]
      seconds = since ? Since.new(since).to_i : Since::DEFAULT
      (Time.now.to_i - seconds) * 1000 # past 10 minutes in milliseconds
    end

    def current_now
      (Time.now.to_i) * 1000 # now in milliseconds
    end

    def end_loop?
      return true if @@end_loop_signal
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
