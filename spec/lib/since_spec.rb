describe AwsLogs::Since do
  let(:since) { AwsLogs::Since.new(str) }

  context "friendly format" do
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

  context "iso8601 format" do
    context "2018-08-08 08:08:08" do
      let(:str) { "2018-08-08 08:08:08" }
      it "2018-08-08 08:08:08" do
        expect(since.to_i).to be_a(Integer)
      end
    end
  end
end
