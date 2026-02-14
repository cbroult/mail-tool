# frozen_string_literal: true

RSpec.describe MailTool::Commands::ListFolders do
  let(:mock_imap) { instance_double(Net::IMAP) }

  def mailbox(name, attrs = [:Hasnochildren])
    Net::IMAP::MailboxList.new(attrs, ".", name)
  end

  describe "#call" do
    it "returns folder names sorted alphabetically" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("Zebra"),
                                                                    mailbox("Alpha"),
                                                                    mailbox("Middle")
                                                                  ])

      result = described_class.new(mock_imap).call

      expect(result.map(&:name)).to eq(%w[Alpha Middle Zebra])
    end

    it "returns all folders when no filter is given" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("INBOX"),
                                                                    mailbox("Sent"),
                                                                    mailbox("Drafts")
                                                                  ])

      result = described_class.new(mock_imap).call

      expect(result.map(&:name)).to eq(%w[Drafts INBOX Sent])
    end

    it "filters folders by regex pattern" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("INBOX"),
                                                                    mailbox("INBOX.Subfolder"),
                                                                    mailbox("Sent"),
                                                                    mailbox("Trash")
                                                                  ])

      result = described_class.new(mock_imap).call(filter: /^INBOX/)

      expect(result.map(&:name)).to eq(["INBOX", "INBOX.Subfolder"])
    end

    it "returns an empty array when no folders exist" do
      allow(mock_imap).to receive(:list).with("", "*").and_return(nil)

      result = described_class.new(mock_imap).call

      expect(result).to eq([])
    end

    it "preserves folder attributes" do
      allow(mock_imap).to receive(:list).with("", "*").and_return([
                                                                    mailbox("INBOX", %i[Noinferiors Hasnochildren])
                                                                  ])

      result = described_class.new(mock_imap).call

      expect(result.first.attr).to eq(%i[Noinferiors Hasnochildren])
    end
  end
end
