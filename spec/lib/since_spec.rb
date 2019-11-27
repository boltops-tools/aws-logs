describe AwsLogs::Since do
  subject(:since) { AwsLogs::Since.new(str) }

  context "5m" do
    let(:str) { "5m" }
    it "5m" do
      expect(since.to_i).to eq 300
    end
  end

  context "1hr" do
    let(:str) { "1h" }
    it "1h" do
      expect(since.to_i).to eq 3600
    end
  end

  context "junk" do
    let(:str) { "junk" }
    it "junk" do
      expect(since.to_i).to eq 600 # fallback
    end
  end
end

