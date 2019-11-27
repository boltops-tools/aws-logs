module AwsLogs
  class Tail
    include AwsServices

    def initialize(options)
      @options = options
      @log_group = options[:log_group]
    end

    def run
      tail
    end

    def tail
      start_time = (Time.now.to_i - 600) * 1000 # past 10 minutes in milliseconds
      # end_time = Time.now.to_i * 1000

      start = Time.now
      resp = cloudwatchlogs.filter_log_events(
        log_group_name: @log_group, # required
        # log_stream_name: '', # LogStreamName", # required
        start_time: start_time,
        # end_time: end_time,
        # next_token: "NextToken",
        limit: 10,
        # start_from_head: false,
      )
      # pp resp

      puts "resp.events.size #{resp.events.size}"
      puts "resp.searched_log_streams.size #{resp.searched_log_streams.size}"
      puts "resp.next_token #{resp.next_token.inspect}"
      finish = Time.now
      puts "duration: #{finish - start}"

      resp.events.each do |e|
        time = Time.at(e.timestamp/1000).utc
        puts "#{time} #{e.log_stream_name} #{e.message}"
      end
    end
  end
end
