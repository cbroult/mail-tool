# mail-tool — Ruby CLI for IMAP Folder Management

## Project Overview

A Ruby CLI tool that connects to IMAP servers to list and rename mail folders. The rename command supports regex pattern matching with backreferences, enabling powerful batch folder reorganization.

## Technology Stack

| Choice | Value |
|--------|-------|
| Language | Ruby (>= 3.0) |
| Protocol | IMAP only (`net/imap` stdlib) |
| CLI framework | Thor (~> 1.5) |
| Unit testing | RSpec (~> 3.13) |
| BDD / Acceptance testing | Cucumber (~> 9.0) + Aruba (~> 2.3) |
| Credentials | Config file (`~/.mail-tool.yml`) + CLI flags (flags override config) |

## Project Structure

```
mail-tool/
  .gitignore
  .rspec
  Gemfile
  Rakefile
  mail-tool.gemspec
  bin/
    mail-tool                    # executable entry point
  lib/
    mail_tool.rb                 # top-level requires, VERSION, error classes
    mail_tool/
      cli.rb                     # Thor CLI (commands, options, output, error handling)
      configuration.rb           # config file loading + CLI flag merging
      connection.rb              # IMAP connect/login/disconnect wrapper
      commands/
        list_folders.rb          # folder listing logic
        rename_folders.rb        # pattern-matched folder renaming logic
      testing/
        mock_imap.rb             # mock IMAP adapter for Cucumber (env-var driven)
  spec/
    spec_helper.rb
    mail_tool/
      cli_spec.rb
      configuration_spec.rb
      connection_spec.rb
      commands/
        list_folders_spec.rb
        rename_folders_spec.rb
    fixtures/
      mail_tool.yml              # sample config for tests
  features/
    help.feature                 # BDD scenarios for CLI help output
    list_folders.feature         # BDD scenarios for folder listing
    rename_folders.feature       # BDD scenarios for folder renaming
    support/
      env.rb                     # Aruba configuration
      imap_mock.rb               # mock state setup/teardown hooks
    step_definitions/
      configuration_steps.rb     # config file setup steps
      imap_steps.rb              # IMAP mock state steps
      cli_steps.rb               # CLI invocation and output assertion steps
```

## Class Design

```
MailTool (namespace, VERSION, error classes)
  ├── CLI < Thor              — command definitions, output formatting, error handling
  ├── Configuration           — load YAML config, merge with CLI flags, validate
  ├── Connection              — Net::IMAP lifecycle (connect/login/yield/logout/disconnect)
  │                             Supports MAIL_TOOL_MOCK_IMAP env var for test injection
  ├── Commands::
  │     ├── ListFolders       — imap.list("", "*"), filter, sort, return data
  │     └── RenameFolders     — regex match, gsub replacement, dry-run, batch rename
  └── Testing::
        └── MockImap          — reads mock state from JSON file, used via env var
```

**Merge precedence** (highest wins): CLI flags > config file > defaults (`port: 993`, `ssl: true`)

## CLI Commands

### `mail-tool list [--filter PATTERN]`

```bash
mail-tool list                                    # list all folders
mail-tool list --filter "^INBOX"                  # filter by regex
mail-tool list -s imap.gmail.com -u user -P pass  # override config
```

Output: table of folder names + attributes, sorted alphabetically.

### `mail-tool rename PATTERN REPLACEMENT [--dry-run] [--yes]`

```bash
mail-tool rename "^OldPrefix\." "NewPrefix." --dry-run   # preview changes
mail-tool rename "^Work\.(.+)" 'Archive.\1'               # with backreferences
mail-tool rename "^Temp\." "Archive.Temp." --yes           # skip confirmation
```

- PATTERN is compiled as Ruby `Regexp`, REPLACEMENT uses `String#gsub` (supports `\1`, `\2` backreferences)
- Without `--dry-run`: shows plan, asks confirmation (unless `--yes`), then executes
- Per-folder error handling: if one rename fails, others continue; errors reported at end

### Global Options (all commands)

`--server/-s`, `--port/-p`, `--username/-u`, `--password/-P`, `--ssl`, `--config/-c`

## Error Handling

| Error | Handling |
|-------|----------|
| Missing config (server/user/pass) | Print message, exit 1 |
| Connection/SSL/DNS failure | Print message, exit 1 |
| Auth failure | Print message, exit 1 |
| Invalid regex | Print message, exit 1 |
| Individual rename failure | Collect error, continue batch, report at end |
| Ctrl-C | Clean exit (130) |

All IMAP/socket exceptions are translated to `MailTool::ConnectionError` or `MailTool::AuthenticationError` with human-readable messages. Connection cleanup (`logout`/`disconnect`) runs via `ensure`.

## Testing Strategy

### Unit Tests (RSpec)

All unit tests mock `Net::IMAP` — no real IMAP server needed.

- **Configuration**: load/merge/validate logic (unit tests, no mocks)
- **Connection**: correct `Net::IMAP.new`/`login` args, cleanup in `ensure`, exception translation (mock `Net::IMAP`)
- **ListFolders**: returns sorted folders, handles empty list, filters by regex (mock `imap.list`)
- **RenameFolders**: dry-run vs live, backreferences, skip-unchanged, per-folder errors (mock `imap.list` + `imap.rename`)
- **CLI**: integration tests via `MailTool::CLI.start(...)`, assert on stdout/stderr output

### Acceptance Tests (Cucumber + Aruba)

BDD specification-by-example tests that exercise the full CLI as a subprocess.

- **IMAP mocking**: The `MAIL_TOOL_MOCK_IMAP` env var points to a JSON file containing mock state (folders, rename errors). `Connection.connect` checks for this env var and uses `Testing::MockImap` instead of a real IMAP connection when set.
- **list_folders.feature**: all folders, alphabetical sorting, regex filtering, empty mailbox, missing config
- **rename_folders.feature**: dry-run, live rename with `--yes`, backreferences, no matches, per-folder errors, invalid regex

## Development Workflow

- **Always follow BDD/TDD loops when making changes:**
  1. **BDD outer loop**: Write or update Cucumber scenarios first to define the desired behavior
  2. **TDD inner loop**: Write or update RSpec unit tests, then implement the production code (red-green-refactor)
  3. Verify all tests pass with `bundle exec rake` before considering the work done
- Run all tests: `bundle exec rake` (runs both rspec and cucumber)
- Run unit tests: `bundle exec rspec`
- Run acceptance tests: `bundle exec cucumber`
- Run specific spec: `bundle exec rspec spec/mail_tool/configuration_spec.rb`
- Run specific feature: `bundle exec cucumber features/list_folders.feature`
- Run CLI: `bundle exec mail-tool list`

## Implementation Order (BDD + TDD)

1. **Project skeleton** — directory layout, Gemfile, gemspec, bin/mail-tool, spec_helper ✅
2. **Cucumber/Aruba setup** — features, step definitions, mock IMAP support ✅
3. **Configuration** — RSpec tests first, then implementation ✅
4. **Connection** — RSpec tests first, then implementation ✅
5. **ListFolders command** — RSpec tests first, then implementation ✅
6. **RenameFolders command** — RSpec tests first, then implementation ✅
7. **CLI layer** — wire commands to Thor, make Cucumber scenarios pass ✅
8. **Polish** — git init, final `bundle exec rake` run ✅

## Environment Notes

- Ruby 4.0.1 via rvm
- `net-imap`, `logger`, `rake` are gem dependencies (removed from stdlib in Ruby 4.0)
- `Net::IMAP::NoResponseError` and `BadResponseError` require a response object, not a plain string — construct via `Net::IMAP::TaggedResponse.new("NO", "NO", Net::IMAP::ResponseText.new(nil, "message"), nil)`
- Aruba runs commands as subprocesses — in-process mocking doesn't work; use env var (`MAIL_TOOL_MOCK_IMAP`) pointing to a JSON fixture file instead
