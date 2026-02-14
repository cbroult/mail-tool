require "json"

module MailTool
  module Testing
    class MockImap
      def initialize(mock_path)
        @state = JSON.parse(File.read(mock_path))
        @rename_errors = @state.fetch("rename_errors", {})
        @delimiter = @state.fetch("delimiter", MailTool::DEFAULT_HIERARCHY_DELIMITER)
      end

      def list(_refname, _mailbox)
        @state.fetch("folders", []).map do |name|
          Net::IMAP::MailboxList.new([:Hasnochildren], @delimiter, name)
        end
      end

      def rename(from, to)
        folders = @state.fetch("folders", [])

        unless folders.include?(from)
          no_resp = Net::IMAP::TaggedResponse.new(
            "NO", "NO", Net::IMAP::ResponseText.new(nil, "Mailbox does not exist: #{from}"), nil
          )
          raise Net::IMAP::NoResponseError, no_resp
        end

        if @rename_errors.key?(from)
          bad_resp = Net::IMAP::TaggedResponse.new(
            "BAD", "BAD", Net::IMAP::ResponseText.new(nil, @rename_errors[from]), nil
          )
          raise Net::IMAP::BadResponseError, bad_resp
        end

        prefix = "#{from}#{@delimiter}"
        @state["folders"] = folders.map do |name|
          if name == from
            to
          elsif name.start_with?(prefix)
            "#{to}#{@delimiter}#{name.delete_prefix(prefix)}"
          else
            name
          end
        end
      end

      def login(_username, _password); end
      def authenticate(_mechanism, _username, _token); end
      def logout; end
      def disconnect; end
    end
  end
end
