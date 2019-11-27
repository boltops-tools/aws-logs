describe AwsLogs::Tail do
  let(:tail) do
    tail = AwsLogs::Tail.new
    allow(tail).to receive(:cloudwatchlogs).and_return(cloudwatchlogs)
    tail
  end

  let(:cloudwatchlogs) do
    logs = double(:logs).as_null_object
    allow(logs).to receive(:filter_log_events).and_return(
      mock_response("spec/fixtures/typical/events-1.json"),
      mock_response("spec/fixtures/typical/events-2.json"),
      mock_response("spec/fixtures/typical/events-3.json"),
      mock_response("spec/fixtures/typical/events-4.json"),
    )
    logs
  end

  describe "tail" do
    it "tail" do
      tail.run
    end
  end
end
