require "json"

module AwsLogs
  class Tail
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group = options[:log_group]
      @loop_count = 0
      @output = [] # for specs
      reset
      set_trap
    end

    @@end_loop_signal = false
    def set_trap
      Signal.trap("INT") {
        puts "\nCtrl-C detected. Exiting..."
        @@end_loop_signal = true
      }
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
      since, now = initial_since, current_now
      while true && !end_loop?
        refresh_events(since, now)
        display
        since, now = now, current_now
        loop_count!
        sleep 5 unless ENV["AWS_LOGS_TEST"]
      end
    end

    def refresh_events(start_time, end_time)
      @events = []
      next_token = :start

      # TODO: can hit throttle limit if there are lots of pages
      while next_token
        resp = cloudwatchlogs.filter_log_events(
          log_group_name: @log_group, # required
          start_time: start_time,
          end_time: end_time,
          # limit: 10,
        )

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
        say "#{time.to_s.color(:green)} #{e.log_stream_name.color(:purple)} #{e.message}"
      end
      @last_shown_event_id = @events.last&.event_id
    end

    def say(text)
      ENV["AWS_LOGS_TEST"] ? @output << text : puts(text)
    end

    def output
      @output.join("\n") + "\n"
    end

  private
    def initial_since
      (Time.now.to_i - 60*60*24*7) * 1000 # past 10 minutes in milliseconds
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
      nil
    end

  end
end
