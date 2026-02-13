RSpec.describe MailTool::Commands::RenameFolders do
  let(:mock_imap) { instance_double(Net::IMAP) }

  def mailbox(name)
    Net::IMAP::MailboxList.new([:Hasnochildren], ".", name)
  end

  before do
    allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                  mailbox("OldPrefix.Folder1"),
                                                                  mailbox("OldPrefix.Folder2"),
                                                                  mailbox("Unrelated")
                                                                ])
    allow(mock_imap).to receive(:rename)
  end

  describe "#call" do
    it "returns planned renames for matching folders" do
      cmd = described_class.new(mock_imap, pattern: /^OldPrefix\./, replacement: "NewPrefix.")

      result = cmd.call(dry_run: true)

      expect(result.planned).to eq([
                                     { from: "OldPrefix.Folder1", to: "NewPrefix.Folder1" },
                                     { from: "OldPrefix.Folder2", to: "NewPrefix.Folder2" }
                                   ])
    end

    it "does not call imap.rename in dry-run mode" do
      cmd = described_class.new(mock_imap, pattern: /^OldPrefix\./, replacement: "NewPrefix.")

      cmd.call(dry_run: true)

      expect(mock_imap).not_to have_received(:rename)
    end

    it "calls imap.rename for each matching folder in live mode" do
      cmd = described_class.new(mock_imap, pattern: /^OldPrefix\./, replacement: "NewPrefix.")

      cmd.call(dry_run: false)

      expect(mock_imap).to have_received(:rename).with("OldPrefix.Folder1", "NewPrefix.Folder1")
      expect(mock_imap).to have_received(:rename).with("OldPrefix.Folder2", "NewPrefix.Folder2")
    end

    it "skips folders where the name does not change" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("Match.Folder"),
                                                                    mailbox("NoChange")
                                                                  ])
      cmd = described_class.new(mock_imap, pattern: /^Match\./, replacement: "Match.")

      result = cmd.call(dry_run: true)

      expect(result.planned).to be_empty
    end

    it "supports backreferences in replacement" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("Work.Projects"),
                                                                    mailbox("Work.Meetings")
                                                                  ])
      cmd = described_class.new(mock_imap, pattern: /^Work\.(.+)/, replacement: 'Archive.\1')

      result = cmd.call(dry_run: true)

      expect(result.planned).to eq([
                                     { from: "Work.Meetings", to: "Archive.Meetings" },
                                     { from: "Work.Projects", to: "Archive.Projects" }
                                   ])
    end

    it "replaces all dots with pipe separators in multi-segment names" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("00.topic.done"),
                                                                    mailbox("01.other.in-progress"),
                                                                    mailbox("NoDots")
                                                                  ])
      cmd = described_class.new(mock_imap, pattern: /\./, replacement: " | ")

      result = cmd.call(dry_run: true)

      expect(result.planned).to eq([
                                     { from: "00.topic.done", to: "00 | topic | done" },
                                     { from: "01.other.in-progress", to: "01 | other | in-progress" }
                                   ])
    end

    it "returns empty planned list when no folders match" do
      cmd = described_class.new(mock_imap, pattern: /^NonExistent\./, replacement: "Other.")

      result = cmd.call(dry_run: true)

      expect(result.planned).to be_empty
    end

    it "collects per-folder errors and continues the batch" do
      bad_response = Net::IMAP::TaggedResponse.new(
        "BAD", "BAD", Net::IMAP::ResponseText.new(nil, "Permission denied"), nil
      )
      allow(mock_imap).to receive(:rename).with("OldPrefix.Folder1", "NewPrefix.Folder1")
      allow(mock_imap).to receive(:rename).with("OldPrefix.Folder2", "NewPrefix.Folder2")
                                          .and_raise(Net::IMAP::BadResponseError.new(bad_response))

      cmd = described_class.new(mock_imap, pattern: /^OldPrefix\./, replacement: "NewPrefix.")

      result = cmd.call(dry_run: false)

      expect(result.renamed_count).to eq(1)
      expect(result.errors).to eq([
                                    { folder: "OldPrefix.Folder2", error: "Permission denied" }
                                  ])
    end

    it "reports renamed count on success" do
      cmd = described_class.new(mock_imap, pattern: /^OldPrefix\./, replacement: "NewPrefix.")

      result = cmd.call(dry_run: false)

      expect(result.renamed_count).to eq(2)
      expect(result.errors).to be_empty
    end
  end
end
