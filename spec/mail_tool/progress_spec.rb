# frozen_string_literal: true

RSpec.describe MailTool::Progress do
  describe ".build" do
    it "returns Silent for 'silent' level" do
      display = described_class.build("silent")
      expect(display).to be_a(MailTool::Progress::Silent)
    end

    it "returns Log for 'log' level" do
      display = described_class.build("log")
      expect(display).to be_a(MailTool::Progress::Log)
    end

    it "returns Inline for 'inline' level" do
      display = described_class.build("inline")
      expect(display).to be_a(MailTool::Progress::Inline)
    end

    it "returns ProgressBar for 'progress_bar' level" do
      display = described_class.build("progress_bar")
      expect(display).to be_a(MailTool::Progress::ProgressBar)
    end

    it "raises MailTool::Error for invalid level" do
      expect { described_class.build("bogus") }.to raise_error(
        MailTool::Error, /Invalid progress level 'bogus'/
      )
    end
  end

  describe "LEVELS" do
    it "contains all four levels" do
      expect(described_class::LEVELS).to eq(%w[silent log inline progress_bar])
    end
  end

  describe "DEFAULT_LEVEL" do
    it "is progress_bar" do
      expect(described_class::DEFAULT_LEVEL).to eq("progress_bar")
    end
  end
end
