require "json"

module AwsLogs
  class Tail
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group = options[:log_group]
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

    # So the start and end time will limit results and make the API fast.
    # 1. load all events from since time
    # 2. after that load events from the last found event or time now now?
    # 3. time now is even better
    #
    # However, events can still be duplicated as events can be written to the exact same timestamp.
    # So also track the last_shown_event_id and prevent duplicate log lines from re-appearing.
    #
    def run
      since, now = initial_since, current_now
      puts "end_loop? #{end_loop?.inspect}"
      while true && !end_loop?
        refresh_events(since, now)
        display
        puts "=" * 30
        since, now = now, current_now
        loop_count!
        sleep 5 unless ENV["AWS_LOGS_TEST"]
      end
    end

    def refresh_events(start_time, end_time)
      puts "refresh_events called".color(:green)
      @events = []
      next_token = :start

      # TODO: within this loop can hit throttle easily
      while next_token
        resp = cloudwatchlogs.filter_log_events(
          log_group_name: @log_group, # required
          start_time: start_time,
          end_time: end_time,
          # limit: 10,
        )

        # puts "resp:"
        # pp resp

        @events += resp.events
        next_token = resp.next_token
      end

      puts "@events.size #{@events.size}"
      @events
    end

    def initial_since
      (Time.now.to_i - 60*60*24*7) * 1000 # past 10 minutes in milliseconds
    end

    def current_now
      (Time.now.to_i) * 1000 # now in milliseconds
    end

    @@loop_count = 0
    def end_loop?
      return true if @@end_loop_signal
      max_loop_count && @@loop_count >= max_loop_count
    end

    def loop_count!
      @@loop_count += 1
    end

    # Useful for specs
    def max_loop_count
      nil
    end

    def display
      puts "display:"
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
      puts text
    end
  end
end
