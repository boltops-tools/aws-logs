require "json"

module AwsLogs
  class Tail
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group_name = options[:log_group_name]
      # Setting to ensure matches default CLI option
      @follow = @options[:follow].nil? ? true : @options[:follow]

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

      # We overlap the sliding window because CloudWatch logs can receive or send the logs out of order.
      # For example, a bunch of logs can all come in at the same second, but they haven't registered to CloudWatch logs
      # yet. If we don't overlap the sliding window then we'll miss the logs that were delayed in registering.
      overlap = 60*1000 # overlap the sliding window by a minute
      since, now = initial_since, current_now
      until end_loop?
        refresh_events(since, now)
        display
        since, now = now-overlap, current_now
        loop_count!
        sleep 5 if @follow && !ENV["AWS_LOGS_TEST"]
      end
      # Refresh and display a final time in case the end_loop gets interrupted by stop_follow!
      refresh_events(since, now)
      display
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
          # limit: 1000,
          # interleaved: true,
        }
        options[:log_stream_names] = @options[:log_stream_names] if @options[:log_stream_names]
        options[:log_stream_name_prefix] = @options[:log_stream_name_prefix] if @options[:log_stream_name_prefix]
        options[:filter_pattern] = @options[:filter_pattern] if @options[:filter_pattern]
        options[:next_token] = next_token if next_token != :start && !next_token.nil?
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
      @@end_loop_signal = messages.detect { |m| m.include?(follow_until) }
    end

    def say(text)
      ENV["AWS_LOGS_TEST"] ? @output << text : puts(text)
    end

    def output
      @output.join("\n") + "\n"
    end

    def set_trap
      Signal.trap("INT") {
        puts "\nCtrl-C detected. Exiting..."
        exit # immediate exit
      }
    end

    # The stop_follow! results in a little waiting because it signals to break the polling loop.
    # Since it's in the middle of the loop process, the loop will finish the sleep 5 first.
    # So it can pause from 0-5 seconds.
    @@end_loop_signal = false
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
