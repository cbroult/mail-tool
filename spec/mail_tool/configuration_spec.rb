RSpec.describe MailTool::Configuration do
  let(:fixture_path) { File.expand_path("../fixtures/mail_tool.yml", __dir__) }

  describe ".load" do
    it "loads settings from a YAML config file" do
      config = described_class.load(config_path: fixture_path)

      expect(config.server).to eq("imap.example.com")
      expect(config.port).to eq(993)
      expect(config.username).to eq("user@example.com")
      expect(config.password).to eq("secret")
      expect(config.ssl).to eq(true)
    end

    it "uses defaults for port and ssl when not in config file" do
      config = described_class.load(config_path: nil)

      expect(config.port).to eq(993)
      expect(config.ssl).to eq(true)
    end

    it "returns defaults when config file does not exist" do
      config = described_class.load(config_path: "/nonexistent/path.yml")

      expect(config.server).to be_nil
      expect(config.port).to eq(993)
      expect(config.ssl).to eq(true)
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
      expect(config.ssl).to eq(false)
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
end
