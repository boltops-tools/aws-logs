$stdout.sync = true unless ENV["AWS_LOGS_STDOUT_SYNC"] == "0"

$:.unshift(File.expand_path("../", __FILE__))
require "aws_logs/version"
require "rainbow/ext/string"

require "aws_logs/autoloader"
AwsLogs::Autoloader.setup

module AwsLogs
  class Error < StandardError; end
end
