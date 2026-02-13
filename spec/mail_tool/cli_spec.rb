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
        described_class.start(["rename", "^Old\\.", "New.", "--yes", "--config", config_path])
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

    it "reports per-folder errors" do
      bad_response = Net::IMAP::TaggedResponse.new(
        "BAD", "BAD", Net::IMAP::ResponseText.new(nil, "Denied"), nil
      )
      allow(mock_imap).to receive(:rename).with("Old.Folder1", "New.Folder1")
      allow(mock_imap).to receive(:rename).with("Old.Folder2", "New.Folder2")
        .and_raise(Net::IMAP::BadResponseError.new(bad_response))

      output = capture_stdout do
        described_class.start(["rename", "^Old\\.", "New.", "--yes", "--config", config_path])
      end

      expect(output).to include("Renamed 1 folder(s)")
      expect(output).to include("Failed to rename Old.Folder2")
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
