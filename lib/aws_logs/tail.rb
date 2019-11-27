require "json"

module AwsLogs
  class Tail
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group = options[:log_group]
      reset
    end

    def reset
      @events = [] # constantly replaced with recent events
      @last_shown_event_id = nil
      @completed = nil
    end

    def refresh_events
      @events = []
      start_time = (Time.now.to_i - 60*60*24*7) * 1000 # past 10 minutes in milliseconds
      next_token = :start

      while next_token
        resp = cloudwatchlogs.filter_log_events(
          log_group_name: @log_group, # required
          start_time: start_time,
          limit: 10,
        )
        @events += resp.events
        next_token = resp.next_token
      end

      puts "@events.size #{@events.size}"
      @events
    end

    def run
      pp refresh_events
      # pp @events.to_h
      # @events.each do |e|
      #   time = Time.at(e.timestamp/1000).utc
      #   puts "#{time.to_s.color(:green)} #{e.log_stream_name.color(:purple)} #{e.message}"
      # end
    end
  end
end
