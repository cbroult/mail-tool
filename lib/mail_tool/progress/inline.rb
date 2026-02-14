# frozen_string_literal: true

module MailTool
  module Progress
    class Inline
      def initialize(output: $stdout)
        @output = output
        @tty = output.respond_to?(:tty?) && output.tty?
        @log_fallback = Log.new(output: output) unless @tty
      end

      def start(_planned); end

      def on_rename(rename, status, error)
        if @tty
          render_inline(rename, status, error)
        else
          @log_fallback.on_rename(rename, status, error)
        end
      end

      def finish
        @output.print "\n" if @tty
      end

      private

      def render_inline(rename, status, _error)
        label = status == :ok ? "DONE" : "FAILED"
        @output.print "\r\e[2KRenaming #{rename[:from]} -> #{rename[:to]} ... #{label}"
      end
    end
  end
end
