ENV["AWS_LOGS_TEST"] = "1"

# CodeClimate test coverage: https://docs.codeclimate.com/docs/configuring-test-coverage
# require 'simplecov'
# SimpleCov.start

require "pp"
require "byebug"
root = File.expand_path("../", File.dirname(__FILE__))
require "#{root}/lib/aws-logs"

module Helper
  def execute(cmd)
    puts "Running: #{cmd}" if show_command?
    out = `#{cmd}`
    puts out if show_command?
    out
  end

  # Added SHOW_COMMAND because DEBUG is also used by other libraries like
  # bundler and it shows its internal debugging logging also.
  def show_command?
    ENV['DEBUG'] || ENV['SHOW_COMMAND']
  end

  def mock_response(file, next_token: nil)
    data = JSON.load(IO.read(file))
    events = data["events"].map do |e|
      Aws::CloudWatchLogs::Types::FilteredLogEvent.new(
        log_stream_name: e["log_stream_name"],
        timestamp: e["timestamp"],
        message: e["message"],
        event_id: e["event_id"],
      )
    end
    Aws::CloudWatchLogs::Types::FilterLogEventsResponse.new(
      events: events,
      next_token: next_token,
    )
  end
end

RSpec.configure do |c|
  c.include Helper
end
