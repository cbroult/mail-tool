module MailTool
  module Commands
    class RenameFolders
      Result = Struct.new(:planned, :renamed_count, :errors, keyword_init: true)

      def initialize(imap, pattern:, replacement:)
        @imap = imap
        @pattern = pattern
        @replacement = replacement
      end

      def call(dry_run: false)
        folders = @imap.list("", "*") || []
        planned = build_plan(folders)

        if dry_run
          Result.new(planned: planned, renamed_count: 0, errors: [])
        else
          execute(planned)
        end
      end

      private

      def build_plan(folders)
        delimiter = folders.first&.delim || DEFAULT_HIERARCHY_DELIMITER
        folders
          .map { |f| { from: f.name, to: f.name.gsub(@pattern, @replacement) } }
          .reject { |r| r[:from] == r[:to] }
          .sort_by { |r| [-r[:from].count(delimiter), r[:from]] }
      end

      def execute(planned)
        errors = []
        renamed = 0

        planned.each do |rename|
          @imap.rename(rename[:from], rename[:to])
          renamed += 1
        rescue StandardError => e
          errors << { folder: rename[:from], error: e.message }
        end

        Result.new(planned: planned, renamed_count: renamed, errors: errors)
      end
    end
  end
end
