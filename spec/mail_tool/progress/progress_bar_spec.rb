# frozen_string_literal: true

RSpec.describe MailTool::Progress::ProgressBar do
  let(:output) do
    StringIO.new.tap { |io| io.define_singleton_method(:tty?) { true } }
  end
  let(:display) { described_class.new(output: output) }
  let(:planned) do
    [
      { from: "A", to: "B" },
      { from: "C", to: "D" }
    ]
  end

  before do
    allow(TTY::Screen).to receive(:width).and_return(80)
  end

  it "creates a progress bar on start" do
    display.start(planned)
    expect(display.instance_variable_get(:@bar)).not_to be_nil
  end

  it "advances the bar on each rename" do
    display.start(planned)
    bar = display.instance_variable_get(:@bar)
    expect(bar).to receive(:advance).twice
    display.on_rename(planned[0], :ok, nil)
    display.on_rename(planned[1], :ok, nil)
  end

  it "advances the bar on errors too" do
    display.start(planned)
    bar = display.instance_variable_get(:@bar)
    expect(bar).to receive(:advance)
    display.on_rename(planned[0], :error, "fail")
  end

  it "includes ETA in the progress bar format" do
    display.start(planned)
    expect(display.instance_variable_get(:@bar).instance_variable_get(:@format)).to include("ETA: :eta")
  end

  it "renders ETA in the output" do
    display.start(planned)
    display.on_rename(planned[0], :ok, nil)
    display.on_rename(planned[1], :ok, nil)
    expect(output.string).to match(/ETA:\s+\d/)
  end
end
