require "aws-sdk-cloudwatchlogs"

require "aws_mfa_secure/ext/aws" # add MFA support

module AwsLogs
  module AwsServices
    def cloudwatchlogs
      @cloudwatchlogs ||= Aws::CloudWatchLogs::Client.new
    end
  end
end
