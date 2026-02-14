# frozen_string_literal: true

RSpec.describe MailTool::Progress::Silent do
  let(:output) { StringIO.new }
  let(:display) { described_class.new(output: output) }
  let(:rename) { { from: "A", to: "B" } }

  it "produces no output on start" do
    display.start([rename])
    expect(output.string).to be_empty
  end

  it "produces no output on successful rename" do
    display.on_rename(rename, :ok, nil)
    expect(output.string).to be_empty
  end

  it "produces no output on failed rename" do
    display.on_rename(rename, :error, "denied")
    expect(output.string).to be_empty
  end

  it "produces no output on finish" do
    display.finish
    expect(output.string).to be_empty
  end
end
