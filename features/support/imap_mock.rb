require "English"
require "json"
require "yaml"
require "tmpdir"

# Since Aruba runs CLI commands as subprocesses, we inject mock state
# via a JSON fixture file. The CLI's Connection class checks the
# MAIL_TOOL_MOCK_IMAP env var and uses mock data if present.
#
# Strategy: we write mock state to a temp file and set the env var
# eagerly in the Before hook. Given steps that modify @mock_state
# call sync_mock! to update the file on disk before the When step runs.

module MockHelper
  def mock_imap_path
    @mock_imap_path ||= begin
      dir = File.join(Dir.tmpdir, "mail-tool-test-#{$PROCESS_ID}-#{rand(100_000)}")
      FileUtils.mkdir_p(dir)
      File.join(dir, "imap_mock.json")
    end
  end

  def sync_mock!
    File.write(mock_imap_path, JSON.dump(@mock_state))
    set_environment_variable("MAIL_TOOL_MOCK_IMAP", mock_imap_path)
  end
end

World(MockHelper)

Before do
  @mock_state = { "folders" => [], "rename_errors" => {} }
  sync_mock!
end

After do
  FileUtils.rm_rf(File.dirname(@mock_imap_path)) if @mock_imap_path && File.exist?(@mock_imap_path)
end
