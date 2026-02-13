require "json"

module MailTool
  module Testing
    class MockImap
      def initialize(mock_path)
        @state = JSON.parse(File.read(mock_path))
        @rename_errors = @state.fetch("rename_errors", {})
      end

      def list(_refname, _mailbox)
        @state.fetch("folders", []).map do |name|
          Net::IMAP::MailboxList.new([:Hasnochildren], ".", name)
        end
      end

      def rename(from, to)
        if @rename_errors.key?(from)
          raise Net::IMAP::BadResponseError, @rename_errors[from]
        end
      end

      def login(_username, _password); end
      def authenticate(_mechanism, _username, _token); end
      def logout; end
      def disconnect; end
    end
  end
end
