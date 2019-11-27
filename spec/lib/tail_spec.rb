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
  context "filter_log_events with 1 cloudwatch api call" do
    let(:tail) do
      tail = AwsLogs::Tail.new
      allow(tail).to receive(:cloudwatchlogs).and_return(cloudwatchlogs)
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
        expect(tail.output).to eq(<<~EOL)
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
          tail.events = mock_response("spec/fixtures/typical/events-2.json").events
        end
        tail
      end

      it "run" do
        tail.run
        expect(tail.output).to eq(<<~EOL)
         2019-11-27 21:06:50 UTC stream-name message1
         2019-11-27 21:07:00 UTC stream-name message2
        EOL
      end
    end

    context "2 calls" do
      let(:tail) do
        tail = AwsLogs::Tail.new
        mock_call_count = 0
        allow(tail).to receive(:refresh_events) do |start_time,end_time|
          if mock_call_count == 0
            tail.events = mock_response("spec/fixtures/typical/events-1.json").events
          else
            tail.events = mock_response("spec/fixtures/typical/events-2.json").events
          end
          mock_call_count += 1
        end
        tail
      end

      it "even though the mocked events are overrlapping it only prints out the lines once" do
        allow(tail).to receive(:max_loop_count).and_return(2)
        tail.run
        expect(tail.output).to eq(<<~EOL)
         2019-11-27 21:06:50 UTC stream-name message1
         2019-11-27 21:07:00 UTC stream-name message2
        EOL
      end
    end
  end
end
