module AwsLogs
  class CLI < Command
    desc "tail LOG_GROUP", "Tail the CloudWatch log group."
    long_desc Help.text(:tail)
    option :since, desc: "From what time to begin displaying logs.  By default, logs will be displayed starting from 10m in the past. The value provided can be an ISO 8601 timestamp or a relative time. Examples: 10m 2d 2w"
    option :follow, default: true, type: :boolean, desc: " Whether to continuously poll for new logs. To exit from this mode, use Control-C."
    option :format, default: "detailed", desc: "The format to display the logs. IE: detailed, short, plain.  With detailed, the log stream name is also shown. Plain is the simplest andd does not show the timestamp or log stream name."
    option :log_stream_names, type: :array, desc: "Filters the results to only logs from the log streams. Can only use log_stream_names or log_stream_name_prefix but not both."
    option :log_stream_name_prefix, desc: "Filters the results to include only events from log streams that have names starting with this prefix. Can only use log_stream_names or log_stream_name_prefix but not both."
    option :filter_pattern, desc: "The filter pattern to use. If not provided, all the events are matched"
    option :follow_until, desc: "Exit out of the follow loop once this text is found."
    def tail(log_group_name)
      Tail.new(options.merge(log_group_name: log_group_name)).run
    end

    desc "streams LOG_GROUP", "Show the log group stream names. Limits on only one page of results."
    long_desc Help.text(:streams)
    option :descending, desc: "True by default if order-by is LastEventTime, false if order-by is LogStreamName"
    option :order_by, default: "LastEventTime", desc: "accepts LogStreamName, LastEventTime"
    def streams(log_group_name)
      Streams.new(options.merge(log_group_name: log_group_name)).run
    end

    desc "completion *PARAMS", "Prints words for auto-completion."
    long_desc Help.text(:completion)
    def completion(*params)
      Completer.new(CLI, *params).run
    end

    desc "completion_script", "Generates a script that can be eval to setup auto-completion."
    long_desc Help.text(:completion_script)
    def completion_script
      Completer::Script.generate
    end

    desc "version", "prints version"
    def version
      puts VERSION
    end
  end
end
