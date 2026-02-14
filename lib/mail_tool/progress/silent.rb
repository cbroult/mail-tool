# frozen_string_literal: true

module MailTool
  module Progress
    class Silent
      def initialize(output: $stdout)
        @output = output
      end

      def start(_planned); end

      def on_rename(_rename, _status, _error); end

      def finish; end
    end
  end
end
