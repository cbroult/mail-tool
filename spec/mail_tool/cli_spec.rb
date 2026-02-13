require "tmpdir"

RSpec.describe MailTool::CLI do
  let(:mock_imap) { instance_double(Net::IMAP) }
  let(:config_path) { File.expand_path("../fixtures/mail_tool.yml", __dir__) }

  def mailbox(name, attrs = [:Hasnochildren])
    Net::IMAP::MailboxList.new(attrs, ".", name)
  end

  before do
    allow(MailTool::Connection).to receive(:connect).and_yield(mock_imap)
  end

  describe "list" do
    it "lists all folders" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
        mailbox("INBOX"),
        mailbox("Sent"),
        mailbox("Drafts")
      ])

      output = capture_stdout do
        described_class.start(["list", "--config", config_path])
      end

      expect(output).to include("Drafts")
      expect(output).to include("INBOX")
      expect(output).to include("Sent")
    end

    it "filters folders by regex" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
        mailbox("INBOX"),
        mailbox("INBOX.Sub"),
        mailbox("Sent")
      ])

      output = capture_stdout do
        described_class.start(["list", "--filter", "^INBOX", "--config", config_path])
      end

      expect(output).to include("INBOX")
      expect(output).to include("INBOX.Sub")
      expect(output).not_to include("Sent")
    end

    it "shows message when no folders found" do
      allow(mock_imap).to receive(:list).with("", "*").and_return(nil)

      output = capture_stdout do
        described_class.start(["list", "--config", config_path])
      end

      expect(output).to include("No folders found")
    end

    it "exits with error when config is missing required fields" do
      output = capture_stderr do
        expect {
          described_class.start(["list", "--config", "/nonexistent/path.yml"])
        }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      expect(output).to include("server is required")
    end

    it "uses default config path when --config is not given" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([mailbox("INBOX")])

      fake_home = Dir.mktmpdir("mail-tool-cli-test")
      default_dir = File.join(fake_home, ".config", "mail-tool")
      FileUtils.mkdir_p(default_dir)
      File.write(File.join(default_dir, "config.yml"), YAML.dump(
        "server" => "imap.example.com", "username" => "user@example.com",
        "password" => "secret", "port" => 993, "ssl" => true
      ))

      output = nil
      begin
        original_home = ENV["HOME"]
        ENV["HOME"] = fake_home

        output = capture_stdout do
          described_class.start(["list"])
        end
      ensure
        ENV["HOME"] = original_home
        FileUtils.rm_rf(fake_home)
      end

      expect(output).to include("INBOX")
    end

    it "auto-creates default config template when no config exists" do
      fake_home = Dir.mktmpdir("mail-tool-cli-test")

      begin
        original_home = ENV["HOME"]
        ENV["HOME"] = fake_home

        output = capture_stdout do
          expect {
            described_class.start(["list"])
          }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end

        expect(output).to include("Config file created at")
      ensure
        ENV["HOME"] = original_home
      end

      template_path = File.join(fake_home, ".config", "mail-tool", "config.yml")
      expect(File.exist?(template_path)).to be true
      content = YAML.safe_load_file(template_path)
      expect(content["server"]).to eq("imap.example.com")
      FileUtils.rm_rf(fake_home)
    end
  end

  describe "rename" do
    before do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
        mailbox("Old.Folder1"),
        mailbox("Old.Folder2"),
        mailbox("Keep")
      ])
      allow(mock_imap).to receive(:rename)
    end

    it "shows plan and renames with --yes" do
      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--yes", "--no-dry-run", "--config", config_path])
      end

      expect(output).to include("Old.Folder1 -> New.Folder1")
      expect(output).to include("Old.Folder2 -> New.Folder2")
      expect(output).to include("Renamed 2 folder(s)")
    end

    it "shows plan without renaming with --dry-run" do
      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--dry-run", "--config", config_path])
      end

      expect(output).to include("Old.Folder1 -> New.Folder1")
      expect(output).to include("Old.Folder2 -> New.Folder2")
      expect(output).to include("Dry run")
      expect(mock_imap).not_to have_received(:rename)
    end

    it "shows message when no folders match" do
      output = capture_stdout do
        described_class.start(["rename", "^Nope\\.", "X.", "--dry-run", "--config", config_path])
      end

      expect(output).to include("No folders match")
    end

    it "exits with error on invalid regex" do
      output = capture_stderr do
        expect {
          described_class.start(["rename", "[invalid", "x", "--dry-run", "--config", config_path])
        }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      expect(output).to include("Invalid regex")
    end

    it "prompts for confirmation and executes on confirm" do
      allow_any_instance_of(described_class).to receive(:yes?).and_return(true)

      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--no-dry-run", "--config", config_path])
      end

      expect(output).to include("Old.Folder1 -> New.Folder1")
      expect(output).to include("Renamed 2 folder(s)")
      expect(mock_imap).to have_received(:rename).with("Old.Folder1", "New.Folder1")
      expect(mock_imap).to have_received(:rename).with("Old.Folder2", "New.Folder2")
    end

    it "prompts for confirmation and cancels on decline" do
      allow_any_instance_of(described_class).to receive(:yes?).and_return(false)

      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--no-dry-run", "--config", config_path])
      end

      expect(output).to include("Old.Folder1 -> New.Folder1")
      expect(output).to include("Cancelled")
      expect(output).not_to include("Renamed")
      expect(mock_imap).not_to have_received(:rename)
    end

    it "skips prompt with --yes" do
      expect_any_instance_of(described_class).not_to receive(:yes?)

      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--yes", "--no-dry-run", "--config", config_path])
      end

      expect(output).to include("Renamed 2 folder(s)")
      expect(mock_imap).to have_received(:rename).twice
    end

    it "reports per-folder errors" do
      bad_response = Net::IMAP::TaggedResponse.new(
        "BAD", "BAD", Net::IMAP::ResponseText.new(nil, "Denied"), nil
      )
      allow(mock_imap).to receive(:rename).with("Old.Folder1", "New.Folder1")
      allow(mock_imap).to receive(:rename).with("Old.Folder2", "New.Folder2")
        .and_raise(Net::IMAP::BadResponseError.new(bad_response))

      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--yes", "--no-dry-run", "--config", config_path])
      end

      expect(output).to include("Renamed 1 folder(s)")
      expect(output).to include("Failed to rename Old.Folder2")
    end
  end

  describe "authorize" do
    let(:oauth2_config_path) { File.expand_path("../fixtures/mail_tool_oauth2.yml", __dir__) }
    let(:mock_flow) { instance_double(MailTool::OAuth2Flow) }
    let(:token_store_path) { File.join(Dir.tmpdir, "mail-tool-cli-test-#{$$}.yml") }

    after do
      File.delete(token_store_path) if File.exist?(token_store_path)
    end

    it "rejects non-xoauth2 config" do
      output = capture_stderr do
        expect {
          described_class.start(["authorize", "--config", config_path])
        }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      expect(output).to include("auth_type must be 'xoauth2'")
    end

    it "prints authorization URL and saves tokens" do
      allow(MailTool::OAuth2Flow).to receive(:new).and_return(mock_flow)
      allow(mock_flow).to receive(:authorization_url).and_return("https://example.com/auth?client_id=cid")
      allow(mock_flow).to receive(:redirect_port).and_return(8089)
      allow(mock_flow).to receive(:wait_for_callback).and_return("auth-code")
      allow(mock_flow).to receive(:exchange_code).with("auth-code").and_return(
        access_token: "new-access",
        refresh_token: "new-refresh",
        expires_at: 1800000000
      )

      server = instance_double(TCPServer)
      allow(TCPServer).to receive(:new).and_return(server)

      output = capture_stdout do
        described_class.start(["authorize", "--config", oauth2_config_path, "--token-store", token_store_path])
      end

      expect(output).to include("https://example.com/auth?client_id=cid")
      expect(output).to include("Authorization successful! Tokens saved.")
    end

    it "reports error when oauth2 settings are missing" do
      output = capture_stderr do
        expect {
          described_class.start(["authorize", "--config", config_path,
            "--server", "s", "--username", "u"])
        }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      expect(output).to include("auth_type must be 'xoauth2'")
    end
  end

  # Helpers to capture stdout/stderr
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end
end
