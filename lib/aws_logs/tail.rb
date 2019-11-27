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

    def set_trap
      Signal.trap("INT") {
        puts "\nCtrl-C detected. Exiting..."
        sleep 0.1
        exit
      }
    end

    def reset
      @events = [] # constantly replaced with recent events
      @last_shown_event_id = nil
      @completed = nil
    end

    def refresh_events(start_time, end_time)
      @events = []
      next_token = :start

      while next_token
        resp = cloudwatchlogs.filter_log_events(
          log_group_name: @log_group, # required
          start_time: start_time,
          end_time: end_time,
          limit: 10,
        )
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
      while true && !$end_loop
        refresh_events(since, now) # pass 1
        display
        puts "=" * 30
        since, now = now, current_now
        sleep 1
      end
    end

    def display
      @events.each do |e|
        time = Time.at(e.timestamp/1000).utc
        puts "#{time.to_s.color(:green)} #{e.log_stream_name.color(:purple)} #{e.message}"
      end
    end
  end
end
