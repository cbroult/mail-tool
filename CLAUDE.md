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
| Credentials | Config file (`~/.config/mail-tool/config.yml`) + CLI flags (flags override config) |
| Static analysis | RuboCop (~> 1.75) + rubocop-rspec (~> 3.5) + rubocop-rake (~> 0.6) |
| Dependency audit | bundler-audit (~> 0.9) |

## Project Structure

```
mail-tool/
  .gitignore
  .rspec
  .rubocop.yml                   # RuboCop configuration (tuned for existing style)
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
    authorize.feature            # BDD scenarios for OAuth2 authorize command
    configuration.feature        # BDD scenarios for config file handling
    help.feature                 # BDD scenarios for CLI help output
    list_folders.feature         # BDD scenarios for folder listing (incl. OAuth2)
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
  │                             Default path: ~/.config/mail-tool/config.yml
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
mail-tool list                                    # list all folders (uses default config)
mail-tool list --filter "^INBOX"                  # filter by regex
mail-tool list -s imap.gmail.com -u user -P pass  # override config
mail-tool list --config /path/to/config.yml       # use explicit config file
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

`--server/-s`, `--port/-p`, `--username/-u`, `--password/-P`, `--ssl`, `--config/-c`, `--auth-type`, `--token-store`

## Error Handling

| Error | Handling |
|-------|----------|
| No config file at default path | Auto-create template, print message, exit 1 |
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
- **authorize.feature**: authorize command help, rejects non-xoauth2 config, rejects missing oauth2 settings
- **configuration.feature**: default config path, `--config` override, auto-creation on first run, CLI flag precedence
- **list_folders.feature**: all folders, alphabetical sorting, regex filtering, empty mailbox, missing config, OAuth2 auth with valid tokens, missing tokens error
- **rename_folders.feature**: dry-run, live rename with `--yes`, backreferences, no matches, per-folder errors, invalid regex

## Code Style

- Use comments sparingly. Only comment complex code.
- Use conventional commit messages (see [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)).
- Commits should be signed (e.g., GPG key, SSH key, S/MIME cert).

## Development Workflow

- Changes should be committed to a branch, then merged to `main` via PR.
- **Always follow BDD/TDD loops when making changes:**
  1. **BDD outer loop**: Write or update Cucumber scenarios first to define the desired behavior
  2. **TDD inner loop**: Write or update RSpec unit tests, then implement the production code (red-green-refactor)
  3. Verify all tests pass with `bundle exec rake` before considering the work done
- Run all tests + lint: `bundle exec rake` (runs rspec, cucumber, rubocop, and bundler-audit)
- Run unit tests: `bundle exec rspec`
- Run acceptance tests: `bundle exec cucumber`
- Run specific spec: `bundle exec rspec spec/mail_tool/configuration_spec.rb`
- Run specific feature: `bundle exec cucumber features/list_folders.feature`
- Run linter: `bundle exec rubocop` (auto-correct with `-A`)
- Run dependency audit: `bundle exec bundler-audit check`
- Run all static analysis: `bundle exec rake lint`
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

## Static Analysis

- **RuboCop** (`.rubocop.yml`): configured to match existing code style (double quotes, no frozen string literal comments, relaxed metrics for CLI methods). Uses `plugins` format for rubocop-rspec and rubocop-rake extensions.
- **bundler-audit**: checks for known vulnerabilities in gem dependencies.
- The `rake` default task runs: `spec` → `features` → `lint` (rubocop + audit). Tests run first for faster feedback.
- All code must pass `bundle exec rubocop` with zero offenses before merging.

## Environment Notes

- Ruby 4.0.1 via rvm
- `net-imap`, `logger`, `rake` are gem dependencies (removed from stdlib in Ruby 4.0)
- `Net::IMAP::NoResponseError` and `BadResponseError` require a response object, not a plain string — construct via `Net::IMAP::TaggedResponse.new("NO", "NO", Net::IMAP::ResponseText.new(nil, "message"), nil)`
- Aruba runs commands as subprocesses — in-process mocking doesn't work; use env var (`MAIL_TOOL_MOCK_IMAP`) pointing to a JSON fixture file instead
