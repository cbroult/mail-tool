Feature: Configuration
  As a mail user
  I want mail-tool to use a default config file location
  So that I don't have to specify --config every time

  Scenario: Auto-creates default config on first run
    Given no default config directory exists
    When I run `mail-tool list`
    Then the output should contain "Config file created at"
    And the output should contain "edit it with your IMAP settings"
    And the exit status should be 1

  Scenario: Loads config from default path
    Given a config file at the default location with valid credentials
    And the IMAP server has the following folders:
      | INBOX |
      | Sent  |
    When I run `mail-tool list`
    Then the output should contain "INBOX"
    And the output should contain "Sent"
    And the exit status should be 0

  Scenario: Override with --config flag
    Given a config file at the default location with valid credentials
    And a config file with valid credentials
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "INBOX"
    And the exit status should be 0

  Scenario: CLI flags override config file values
    Given a config file at the default location with valid credentials
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list --server other.example.com --username other@example.com`
    Then the output should contain "INBOX"
    And the exit status should be 0

  Scenario: CLI flags override default config
    Given a config file at the default location with valid credentials
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list -s other.example.com -u other@example.com -P otherpass`
    Then the output should contain "INBOX"
    And the exit status should be 0
