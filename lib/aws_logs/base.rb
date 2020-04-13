module AwsLogs
  class Base
    include AwsServices

    def initialize(options={})
      @options = options
      @log_group_name = options[:log_group_name]
    end
  end
end
