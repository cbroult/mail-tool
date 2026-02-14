# frozen_string_literal: true

module MailTool
  module Commands
    class ListFolders
      def initialize(imap)
        @imap = imap
      end

      def call(filter: nil)
        folders = @imap.list("", "*") || []
        folders = folders.select { |f| f.name.match?(filter) } if filter
        folders.sort_by(&:name)
      end
    end
  end
end
