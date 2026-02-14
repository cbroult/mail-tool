# frozen_string_literal: true

RSpec.describe MailTool::Progress::Inline do
  let(:rename) { { from: "Old.Folder", to: "New.Folder" } }

  context "when output is not a TTY" do
    let(:output) { StringIO.new }
    let(:display) { described_class.new(output: output) }

    it "falls back to log format on :ok status" do
      display.on_rename(rename, :ok, nil)
      expect(output.string).to eq("Renamed Old.Folder -> New.Folder\n")
    end

    it "falls back to log format on :error status" do
      display.on_rename(rename, :error, "denied")
      expect(output.string).to eq("FAILED Old.Folder -> New.Folder: denied\n")
    end
  end

  context "when output is a TTY" do
    let(:output) do
      io = StringIO.new
      allow(io).to receive(:tty?).and_return(true)
      io
    end
    let(:display) { described_class.new(output: output) }

    it "prints inline update with DONE on :ok status" do
      display.on_rename(rename, :ok, nil)
      expect(output.string).to include("Renaming Old.Folder -> New.Folder ... DONE")
    end

    it "prints inline update with FAILED on :error status" do
      display.on_rename(rename, :error, "denied")
      expect(output.string).to include("FAILED")
    end

    it "prints trailing newline on finish" do
      display.on_rename(rename, :ok, nil)
      display.finish
      expect(output.string).to end_with("\n")
    end
  end
end
