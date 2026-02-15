# frozen_string_literal: true

module MailTool
  module Progress
    LEVELS = %w[silent log inline progress_bar].freeze
    DEFAULT_LEVEL = "progress_bar"

    STRATEGY_MAP = {
      "silent" => Silent,
      "log" => Log,
      "inline" => Inline,
      "progress_bar" => ProgressBar
    }.freeze

    def self.build(level, output: $stdout)
      unless LEVELS.include?(level)
        raise MailTool::Error, "Invalid progress level '#{level}'. Valid levels: #{LEVELS.join(", ")}"
      end

      STRATEGY_MAP.fetch(level).new(output: output)
    end
  end
end
