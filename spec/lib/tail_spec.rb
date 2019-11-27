describe AwsLogs::Tail do
  let(:tail) do
    tail = AwsLogs::Tail.new
    allow(tail).to receive(:cloudwatchlogs).and_return(cloudwatchlogs)
    tail
  end

  let(:cloudwatchlogs) do
    logs = double(:logs).as_null_object
    # allow(logs).to receive(:filter_log_events).and_return(
    #   mock_response("spec/fixtures/typical/events-1.json", next_token: true),
    #   mock_response("spec/fixtures/typical/events-2.json"),
    #   # mock_response("spec/fixtures/typical/events-3.json"),
    #   # mock_response("spec/fixtures/typical/events-4.json"),
    # )

    allow(logs).to receive(:filter_log_events) do |args|
      puts "args #{args.inspect}"
      if args[:start_time] == 1574888800000 && args[:end_time] == 1574888815000
        puts "hi1"
        mock_response("spec/fixtures/typical/events-2.json")
      else
        puts "hi2"
        $end_loop = true
        mock_response("spec/fixtures/typical/events-3.json")
      end
    end

    # allow(obj).to receive(:message) do |arg1, arg2|
    #   # set expectations about the args in this block
    #   # and/or return  value
    # end
    logs
  end

  describe "tail" do
    it "tail" do
      allow(tail).to receive(:initial_since).and_return(1574888800000)
      allow(tail).to receive(:current_now).and_return(
        1574888815000,
        1574888825000,
        1574888835000,
        1574888845000,
      )
      tail.run
    end
  end
end
