# frozen_string_literal: true

RSpec.describe MailTool::Progress::Log do
  let(:output) { StringIO.new }
  let(:display) { described_class.new(output: output) }
  let(:rename) { { from: "Old.Folder", to: "New.Folder" } }

  it "prints success line on :ok status" do
    display.on_rename(rename, :ok, nil)
    expect(output.string).to eq("Renamed Old.Folder -> New.Folder\n")
  end

  it "prints failure line on :error status" do
    display.on_rename(rename, :error, "Permission denied")
    expect(output.string).to eq("FAILED Old.Folder -> New.Folder: Permission denied\n")
  end

  it "produces no output on start" do
    display.start([rename])
    expect(output.string).to be_empty
  end

  it "produces no output on finish" do
    display.finish
    expect(output.string).to be_empty
  end
end
