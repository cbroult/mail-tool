RSpec.describe MailTool::Configuration do
  let(:fixture_path) { File.expand_path("../fixtures/mail_tool.yml", __dir__) }
  let(:oauth2_fixture_path) { File.expand_path("../fixtures/mail_tool_oauth2.yml", __dir__) }

  describe ".load" do
    it "loads settings from a YAML config file" do
      config = described_class.load(config_path: fixture_path)

      expect(config.server).to eq("imap.example.com")
      expect(config.port).to eq(993)
      expect(config.username).to eq("user@example.com")
      expect(config.password).to eq("secret")
      expect(config.ssl).to be(true)
    end

    it "uses defaults for port and ssl when not in config file" do
      config = described_class.load(config_path: nil)

      expect(config.port).to eq(993)
      expect(config.ssl).to be(true)
    end

    it "returns defaults when config file does not exist" do
      config = described_class.load(config_path: "/nonexistent/path.yml")

      expect(config.server).to be_nil
      expect(config.port).to eq(993)
      expect(config.ssl).to be(true)
    end
  end

  describe "CLI flag merging" do
    it "overrides config file values with CLI flags" do
      config = described_class.load(
        config_path: fixture_path,
        overrides: { server: "other.example.com", port: 143, ssl: false }
      )

      expect(config.server).to eq("other.example.com")
      expect(config.port).to eq(143)
      expect(config.ssl).to be(false)
      expect(config.username).to eq("user@example.com")
      expect(config.password).to eq("secret")
    end

    it "ignores nil override values" do
      config = described_class.load(
        config_path: fixture_path,
        overrides: { server: nil, username: nil }
      )

      expect(config.server).to eq("imap.example.com")
      expect(config.username).to eq("user@example.com")
    end
  end

  describe "#validate!" do
    it "raises ConfigurationError when server is missing" do
      config = described_class.load(config_path: nil, overrides: { username: "u", password: "p" })

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /server is required/
      )
    end

    it "raises ConfigurationError when username is missing" do
      config = described_class.load(config_path: nil, overrides: { server: "s", password: "p" })

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /username is required/
      )
    end

    it "raises ConfigurationError when password is missing" do
      config = described_class.load(config_path: nil, overrides: { server: "s", username: "u" })

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /password is required/
      )
    end

    it "does not raise when all required fields are present" do
      config = described_class.load(config_path: fixture_path)

      expect { config.validate! }.not_to raise_error
    end
  end

  describe ".default_config_path" do
    it "returns ~/.config/mail-tool/config.yml" do
      expected = File.join(Dir.home, ".config", "mail-tool", "config.yml")
      expect(described_class.default_config_path).to eq(expected)
    end
  end

  describe "OAuth2 configuration" do
    it "defaults auth_type to basic" do
      config = described_class.load(config_path: fixture_path)

      expect(config.auth_type).to eq("basic")
    end

    it "defaults token_store to ~/.config/mail-tool/tokens.yml" do
      config = described_class.load(config_path: fixture_path)

      expect(config.token_store).to eq(File.join(Dir.home, ".config", "mail-tool", "tokens.yml"))
    end

    it "loads OAuth2 settings from config file" do
      config = described_class.load(config_path: oauth2_fixture_path)

      expect(config.auth_type).to eq("xoauth2")
      expect(config.oauth2).to be_a(Hash)
      expect(config.oauth2["client_id"]).to eq("test-client-id")
      expect(config.oauth2["client_secret"]).to eq("test-client-secret")
      expect(config.oauth2["authorize_url"]).to eq("https://api.login.yahoo.com/oauth2/request_auth")
      expect(config.oauth2["token_url"]).to eq("https://api.login.yahoo.com/oauth2/get_token")
      expect(config.oauth2["scope"]).to eq("mail-r mail-w")
      expect(config.oauth2["redirect_port"]).to eq(8089)
    end

    it "loads token_store path from config file" do
      config = described_class.load(config_path: oauth2_fixture_path)

      expect(config.token_store).to eq("/tmp/test-tokens.yml")
    end

    it "does not require password when auth_type is xoauth2" do
      config = described_class.load(config_path: oauth2_fixture_path)

      expect { config.validate! }.not_to raise_error
    end

    it "requires oauth2.client_id when auth_type is xoauth2" do
      config = described_class.load(config_path: oauth2_fixture_path)
      config.oauth2.delete("client_id")

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /oauth2\.client_id is required/
      )
    end

    it "requires oauth2.client_secret when auth_type is xoauth2" do
      config = described_class.load(config_path: oauth2_fixture_path)
      config.oauth2.delete("client_secret")

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /oauth2\.client_secret is required/
      )
    end

    it "requires oauth2.authorize_url when auth_type is xoauth2" do
      config = described_class.load(config_path: oauth2_fixture_path)
      config.oauth2.delete("authorize_url")

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /oauth2\.authorize_url is required/
      )
    end

    it "requires oauth2.token_url when auth_type is xoauth2" do
      config = described_class.load(config_path: oauth2_fixture_path)
      config.oauth2.delete("token_url")

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /oauth2\.token_url is required/
      )
    end

    it "requires oauth2 hash when auth_type is xoauth2" do
      config = described_class.load(
        config_path: nil,
        overrides: { server: "s", username: "u", auth_type: "xoauth2" }
      )

      expect { config.validate! }.to raise_error(
        MailTool::ConfigurationError, /oauth2\.client_id is required/
      )
    end

    it "allows token_store override via CLI flags" do
      config = described_class.load(
        config_path: oauth2_fixture_path,
        overrides: { token_store: "/custom/path.yml" }
      )

      expect(config.token_store).to eq("/custom/path.yml")
    end
  end
end
