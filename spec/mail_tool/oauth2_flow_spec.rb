require "oauth2"

RSpec.describe MailTool::OAuth2Flow do
  let(:oauth2_settings) do
    {
      "client_id" => "test-client-id",
      "client_secret" => "test-client-secret",
      "authorize_url" => "https://provider.example.com/oauth2/auth",
      "token_url" => "https://provider.example.com/oauth2/token",
      "scope" => "mail-r mail-w",
      "redirect_port" => 8089
    }
  end

  let(:flow) { described_class.new(oauth2_settings) }
  let(:mock_client) { instance_double(OAuth2::Client) }
  let(:mock_auth_code) { instance_double(OAuth2::Strategy::AuthCode) }

  before do
    allow(OAuth2::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:auth_code).and_return(mock_auth_code)
  end

  describe "#authorization_url" do
    it "returns an authorization URL with correct parameters" do
      allow(mock_auth_code).to receive(:authorize_url).and_return(
        "https://provider.example.com/oauth2/auth?client_id=test-client-id&redirect_uri=http://localhost:8089/callback&scope=mail-r+mail-w&response_type=code"
      )

      url = flow.authorization_url

      expect(mock_auth_code).to have_received(:authorize_url).with(
        redirect_uri: "http://localhost:8089/callback",
        scope: "mail-r mail-w"
      )
      expect(url).to include("provider.example.com")
    end

    it "uses default port 8080 when redirect_port is not set" do
      settings = oauth2_settings.dup
      settings.delete("redirect_port")
      flow_default = described_class.new(settings)

      allow(mock_auth_code).to receive(:authorize_url).and_return("https://example.com")

      flow_default.authorization_url

      expect(mock_auth_code).to have_received(:authorize_url).with(
        redirect_uri: "http://localhost:8080/callback",
        scope: "mail-r mail-w"
      )
    end
  end

  describe "#exchange_code" do
    it "exchanges authorization code for tokens" do
      token = instance_double(OAuth2::AccessToken,
                              token: "access-123",
                              refresh_token: "refresh-456",
                              expires_at: 1_700_000_000)
      allow(mock_auth_code).to receive(:get_token).and_return(token)

      result = flow.exchange_code("auth-code-xyz")

      expect(mock_auth_code).to have_received(:get_token).with(
        "auth-code-xyz",
        redirect_uri: "http://localhost:8089/callback"
      )
      expect(result).to eq(
        access_token: "access-123",
        refresh_token: "refresh-456",
        expires_at: 1_700_000_000
      )
    end
  end

  describe "#refresh_token" do
    it "refreshes an expired token and returns new tokens" do
      old_token = instance_double(OAuth2::AccessToken)
      new_token = instance_double(OAuth2::AccessToken,
                                  token: "new-access",
                                  refresh_token: "new-refresh",
                                  expires_at: 1_800_000_000)
      allow(OAuth2::AccessToken).to receive(:from_hash).and_return(old_token)
      allow(old_token).to receive(:refresh!).and_return(new_token)

      result = flow.refresh_token("old-access", "old-refresh")

      expect(result).to eq(
        access_token: "new-access",
        refresh_token: "new-refresh",
        expires_at: 1_800_000_000
      )
    end
  end

  describe "#wait_for_callback" do
    it "extracts authorization code from HTTP request" do
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]

      thread = Thread.new { flow.wait_for_callback(server) }
      sleep 0.05

      socket = TCPSocket.new("127.0.0.1", port)
      socket.print "GET /callback?code=test-auth-code HTTP/1.1\r\nHost: localhost\r\n\r\n"
      response = socket.read
      socket.close

      code = thread.value
      expect(code).to eq("test-auth-code")
      expect(response).to include("Authorization successful")
    ensure
      server&.close
    end
  end

  describe "OAuth2::Client initialization" do
    it "creates client with correct settings" do
      allow(mock_auth_code).to receive(:authorize_url).and_return("https://example.com")

      flow.authorization_url

      expect(OAuth2::Client).to have_received(:new).with(
        "test-client-id",
        "test-client-secret",
        authorize_url: "https://provider.example.com/oauth2/auth",
        token_url: "https://provider.example.com/oauth2/token"
      )
    end
  end
end
