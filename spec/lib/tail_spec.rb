module AwsLogs
  class Tail
    # Override to 1 as default. Override on a per spec level if needed.
    attr_accessor :events
    def max_loop_count
      1
    end
  end
end

Rainbow.enabled = false

describe AwsLogs::Tail do
  # In this spec we override the cloudwatchlogs client. So this tests the logic pretty deeply.
  context "1 filter_log_events with single events api call" do
    let(:tail) do
      tail = AwsLogs::Tail.new
      allow(tail).to receive(:cloudwatchlogs).and_return(cloudwatchlogs)
      @out = []
      allow(tail).to receive(:say) { |text| @out << text }
      tail
    end
    let(:cloudwatchlogs) do
      logs = double(:logs).as_null_object
      allow(logs).to receive(:filter_log_events).and_return(*filter_log_events_response)
      logs
    end
    let(:filter_log_events_response) do
      [
        mock_response("spec/fixtures/typical/events-2.json"),
      ]
    end

    describe "tail" do
      it "run" do
        tail.run

        text = @out.join("\n") + "\n"
        expect(text).to eq(<<~EOL)
         2019-11-27 21:06:50 UTC stream-name message1
         2019-11-27 21:07:00 UTC stream-name message2
        EOL
      end
    end
  end

  # In the rest of the specs we only override refresh_events.
  context "refresh_events" do
    context "single call" do
      let(:tail) do
        tail = AwsLogs::Tail.new
        allow(tail).to receive(:refresh_events) do
          puts "mocking refresh_events"
          tail.events = mock_response("spec/fixtures/typical/events-2.json").events
        end
        @out = []
        allow(tail).to receive(:say) { |text| @out << text }
        tail
      end

      it "run" do
        tail.run

        text = @out.join("\n") + "\n"
        expect(text).to eq(<<~EOL)
         2019-11-27 21:06:50 UTC stream-name message1
         2019-11-27 21:07:00 UTC stream-name message2
        EOL
      end
    end
  end
end
