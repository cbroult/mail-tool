require "tmpdir"

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

  describe "XOAUTH2 authentication" do
    let(:oauth2_config) do
      MailTool::Configuration.load(
        config_path: nil,
        overrides: {
          server: "imap.example.com",
          port: 993,
          username: "user@example.com",
          ssl: true,
          auth_type: "xoauth2",
          token_store: token_store_path,
          oauth2: {
            "client_id" => "cid",
            "client_secret" => "csec",
            "authorize_url" => "https://example.com/auth",
            "token_url" => "https://example.com/token",
            "scope" => "mail-r"
          }
        }
      )
    end

    let(:token_store_path) { File.join(Dir.tmpdir, "mail-tool-conn-test-#{$$}.yml") }
    let(:token_store) { MailTool::TokenStore.new(token_store_path) }
    let(:token_key) { "imap.example.com/user@example.com" }

    before do
      allow(mock_imap).to receive(:authenticate)
    end

    after do
      File.delete(token_store_path) if File.exist?(token_store_path)
    end

    it "authenticates with XOAUTH2 when auth_type is xoauth2" do
      token_store.save(token_key, access_token: "valid-token", refresh_token: "ref", expires_at: Time.now.to_i + 3600)

      described_class.connect(oauth2_config) { |imap| }

      expect(mock_imap).to have_received(:authenticate).with("XOAUTH2", "user@example.com", "valid-token")
      expect(mock_imap).not_to have_received(:login)
    end

    it "raises ConfigurationError when no tokens are found" do
      expect {
        described_class.connect(oauth2_config) { |imap| }
      }.to raise_error(MailTool::ConfigurationError, /No OAuth2 tokens found.*Run 'mail-tool authorize' first/)
    end

    it "auto-refreshes expired tokens" do
      token_store.save(token_key, access_token: "expired-token", refresh_token: "ref-token", expires_at: Time.now.to_i - 100)

      mock_flow = instance_double(MailTool::OAuth2Flow)
      allow(MailTool::OAuth2Flow).to receive(:new).and_return(mock_flow)
      allow(mock_flow).to receive(:refresh_token).and_return(
        access_token: "refreshed-token",
        refresh_token: "new-ref",
        expires_at: Time.now.to_i + 3600
      )

      described_class.connect(oauth2_config) { |imap| }

      expect(mock_flow).to have_received(:refresh_token).with("expired-token", "ref-token")
      expect(mock_imap).to have_received(:authenticate).with("XOAUTH2", "user@example.com", "refreshed-token")

      # Verify new tokens were saved
      updated = token_store.load(token_key)
      expect(updated["access_token"]).to eq("refreshed-token")
    end

    it "translates XOAUTH2 NoResponseError to AuthenticationError" do
      token_store.save(token_key, access_token: "bad-token", refresh_token: "ref", expires_at: Time.now.to_i + 3600)

      response = Net::IMAP::TaggedResponse.new(
        "NO", "NO", Net::IMAP::ResponseText.new(nil, "AUTHENTICATE failed"), nil
      )
      allow(mock_imap).to receive(:authenticate).and_raise(
        Net::IMAP::NoResponseError.new(response)
      )

      expect {
        described_class.connect(oauth2_config) { |imap| }
      }.to raise_error(MailTool::AuthenticationError, /authentication failed/i)
    end
  end
end
