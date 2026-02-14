# mail-tool

A Ruby CLI for IMAP folder management. List and batch rename mail folders using regex patterns with backreference support.

## Requirements

- Ruby >= 3.0
- Bundler

## Setup

```bash
git clone <repo-url> && cd mail-tool
bundle install
```

## Configuration

On first run, `mail-tool` creates a template config at `~/.config/mail-tool/config.yml`:

```yaml
server: imap.example.com
port: 993
username: user@example.com
password: secret
ssl: true
# auth_type: xoauth2
# token_store: ~/.config/mail-tool/tokens.yml
# oauth2:
#   client_id: your-client-id
#   client_secret: your-client-secret
#   authorize_url: https://provider.example.com/oauth2/auth
#   token_url: https://provider.example.com/oauth2/token
#   scope: mail-r mail-w
#   redirect_port: 8080
```

Edit this file with your IMAP credentials. You can also pass `--config /path/to/config.yml` to use an alternate config, or override individual values with CLI flags.

### OAuth2 / XOAUTH2

To use OAuth2 authentication, set `auth_type: xoauth2` and fill in the `oauth2` section, then run:

```bash
mail-tool authorize
```

This opens a browser for authorization and stores tokens in the configured `token_store` path.

## Usage

### List folders

```bash
mail-tool list                          # list all folders
mail-tool list --filter "^INBOX"        # filter by regex
```

### Rename folders

```bash
mail-tool rename "^Old\." "New." --dry-run         # preview changes
mail-tool rename "^Work\.(.+)" 'Archive.\1' --yes  # backreferences, skip prompt
mail-tool rename "^Temp\." "Archive.Temp."         # prompts for confirmation
```

- `PATTERN` is a Ruby `Regexp`; `REPLACEMENT` uses `String#gsub` syntax (`\1`, `\2` for backreferences)
- `--dry-run` (default) previews without making changes; use `--no-dry-run` to execute
- `--yes` skips the confirmation prompt

### Global options

All commands accept: `--server/-s`, `--port/-p`, `--username/-u`, `--password/-P`, `--ssl`, `--config/-c`, `--auth-type`, `--token-store`

CLI flags take precedence over config file values.

### Help

```bash
mail-tool help
mail-tool help list
mail-tool help rename
mail-tool help authorize
```

## Development

### Running the full suite

```bash
bundle exec rake
```

This runs, in order: RSpec unit tests, Cucumber acceptance tests, RuboCop, and bundler-audit.

### Individual tasks

```bash
bundle exec rspec                                       # unit tests
bundle exec rspec spec/mail_tool/commands/list_folders_spec.rb  # single spec file
bundle exec cucumber                                    # acceptance tests
bundle exec cucumber features/rename_folders.feature    # single feature
bundle exec rubocop                                     # linter (auto-correct with -A)
bundle exec bundler-audit check                         # dependency audit
```

### BDD/TDD workflow

Changes follow a BDD outer loop / TDD inner loop:

1. Write or update a Cucumber scenario in `features/` to define the desired behavior
2. Write or update RSpec examples in `spec/` and implement production code (red-green-refactor)
3. Verify with `bundle exec rake`

### Feature files as living documentation

The Cucumber feature files serve as executable specifications:

| Feature file | Covers |
|---|---|
| `features/help.feature` | CLI help output, global options, unknown commands |
| `features/configuration.feature` | Default config path, `--config` override, auto-creation, CLI flag precedence |
| `features/list_folders.feature` | Folder listing, sorting, regex filtering, empty mailbox, OAuth2 auth |
| `features/rename_folders.feature` | Dry-run, live rename, backreferences, confirmation prompts, per-folder errors |
| `features/authorize.feature` | OAuth2 authorization flow, validation of auth_type and oauth2 settings |

### Testing approach

- **Unit tests (RSpec):** All IMAP interactions are mocked via `instance_double(Net::IMAP)`. No real IMAP server needed.
- **Acceptance tests (Cucumber + Aruba):** The CLI runs as a subprocess. IMAP is mocked via the `MAIL_TOOL_MOCK_IMAP` environment variable pointing to a JSON fixture file.

### Static analysis

- **RuboCop** with `rubocop-rspec` and `rubocop-rake` plugins (config in `.rubocop.yml`)
- **bundler-audit** for known gem vulnerabilities

## License

[MIT](LICENSE)
