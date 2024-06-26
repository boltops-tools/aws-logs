$stdout.sync = true unless ENV["AWS_LOGS_STDOUT_SYNC"] == "0"

$:.unshift(File.expand_path(".", __dir__))

require "aws_logs/core_ext/file"
require "aws_logs/version"
require "rainbow/ext/string"
require "active_support"
require "active_support/core_ext"

require "aws_logs/autoloader"
AwsLogs::Autoloader.setup

module AwsLogs
  class Error < StandardError; end
end
