RSpec.describe MailTool::Connection do
  let(:config) do
    MailTool::Configuration.load(
      config_path: nil,
      overrides: { server: "imap.example.com", port: 993, username: "user", password: "pass", ssl: true }
    )
  end
  let(:mock_imap) { instance_double(Net::IMAP) }

  before do
    allow(Net::IMAP).to receive(:new).and_return(mock_imap)
    allow(mock_imap).to receive(:login)
    allow(mock_imap).to receive(:logout)
    allow(mock_imap).to receive(:disconnect)
  end

  describe ".connect" do
    it "creates an IMAP connection with correct arguments" do
      described_class.connect(config) { |imap| }

      expect(Net::IMAP).to have_received(:new).with("imap.example.com", port: 993, ssl: true)
    end

    it "logs in with username and password" do
      described_class.connect(config) { |imap| }

      expect(mock_imap).to have_received(:login).with("user", "pass")
    end

    it "yields the imap connection to the block" do
      yielded = nil
      described_class.connect(config) { |imap| yielded = imap }

      expect(yielded).to eq(mock_imap)
    end

    it "logs out and disconnects after the block" do
      described_class.connect(config) { |imap| }

      expect(mock_imap).to have_received(:logout)
      expect(mock_imap).to have_received(:disconnect)
    end

    it "disconnects even when an error occurs in the block" do
      expect {
        described_class.connect(config) { |imap| raise "boom" }
      }.to raise_error(RuntimeError, "boom")

      expect(mock_imap).to have_received(:disconnect)
    end

    it "translates SocketError to ConnectionError" do
      allow(Net::IMAP).to receive(:new).and_raise(SocketError.new("getaddrinfo: Name or service not known"))

      expect {
        described_class.connect(config) { |imap| }
      }.to raise_error(MailTool::ConnectionError, /failed to connect.*imap.example.com/i)
    end

    it "translates Errno::ECONNREFUSED to ConnectionError" do
      allow(Net::IMAP).to receive(:new).and_raise(Errno::ECONNREFUSED)

      expect {
        described_class.connect(config) { |imap| }
      }.to raise_error(MailTool::ConnectionError, /failed to connect/i)
    end

    it "translates OpenSSL::SSL::SSLError to ConnectionError" do
      allow(Net::IMAP).to receive(:new).and_raise(OpenSSL::SSL::SSLError.new("SSL_connect"))

      expect {
        described_class.connect(config) { |imap| }
      }.to raise_error(MailTool::ConnectionError, /ssl/i)
    end

    it "translates Net::IMAP::NoResponseError to AuthenticationError" do
      response = Net::IMAP::TaggedResponse.new(
        "NO", "NO", Net::IMAP::ResponseText.new(nil, "LOGIN failed"), nil
      )
      allow(mock_imap).to receive(:login).and_raise(
        Net::IMAP::NoResponseError.new(response)
      )

      expect {
        described_class.connect(config) { |imap| }
      }.to raise_error(MailTool::AuthenticationError, /authentication failed/i)
    end

    it "connects without ssl when ssl is false" do
      config.ssl = false
      config.port = 143

      described_class.connect(config) { |imap| }

      expect(Net::IMAP).to have_received(:new).with("imap.example.com", port: 143, ssl: false)
    end
  end
end
