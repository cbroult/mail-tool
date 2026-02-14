# frozen_string_literal: true

module MailTool
  module Progress
    class Log
      def initialize(output: $stdout)
        @output = output
      end

      def start(_planned); end

      def on_rename(rename, status, error)
        if status == :ok
          @output.puts "Renamed #{rename[:from]} -> #{rename[:to]}"
        else
          @output.puts "FAILED #{rename[:from]} -> #{rename[:to]}: #{error}"
        end
      end

      def finish; end
    end
  end
end
