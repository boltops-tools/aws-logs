module AwsLogs
  class Streams < Base
    def run
      resp = cloudwatchlogs.describe_log_streams(
        log_group_name: @log_group_name,
        descending: descending,
        order_by: order_by,
      )
      names = resp.log_streams.map { |s| s.log_stream_name }
      puts names
    end

  private
    # True by default if order-by is LastEventTime, false if order-by is LogStreamName
    def descending
      return @options[:descending] unless @options[:descending].nil?
      order_by == "LastEventTime"
    end

    def order_by
      @options[:order_by] || "LastEventTime" # accepts LogStreamName, LastEventTime
    end
  end
end
