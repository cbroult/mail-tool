# frozen_string_literal: true

require "tty-progressbar"

module MailTool
  module Progress
    class ProgressBar
      def initialize(output: $stdout)
        @output = output
        @bar = nil
      end

      def start(planned)
        @bar = TTY::ProgressBar.new(
          "Renaming [:bar] :current/:total ETA: :eta",
          total: planned.size,
          output: @output,
          width: 20
        )
      end

      def on_rename(_rename, _status, _error)
        @bar&.advance
      end

      def finish; end
    end
  end
end
