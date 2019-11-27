describe AwsLogs::CLI do
  describe "aws-logs" do
    it "tail" do
      out = execute("AWS_LOGS_NOOP=1 exe/aws-logs tail LOG_GROUP")
      expect(out).to include("Noop test")
    end
  end
end
