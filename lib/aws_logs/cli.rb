module AwsLogs
  class CLI < Command
    class_option :verbose, type: :boolean
    class_option :noop, type: :boolean

    desc "tail LOG_GROUP", "Tail the CloudWatch log group."
    long_desc Help.text(:tail)
    option :since, desc: "From what time to begin displaying logs.  Bydefault, logs will be displayed starting from 10m in the past. The value provided can be an ISO 8601 timestamp or a relative time."
    option :follow, default: true, type: :boolean, desc: " Whether to continuously poll for new logs. To exit from this mode, use Control-C."
    option :format, default: "detailed", desc: "The format to display the logs. IE: detailed or short.  With detailed, the log stream name is also shown."
    option :filter_pattern, desc: "The filter pattern to use. If not provided, all the events are matched"
    def tail(log_group)
      Tail.new(options.merge(log_group: log_group)).run
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
