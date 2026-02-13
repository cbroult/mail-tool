Feature: List mail folders
  As a mail user
  I want to list my IMAP mail folders
  So that I can see how my mailbox is organized

  Background:
    Given a config file with valid credentials

  Scenario: List all folders
    Given the IMAP server has the following folders:
      | INBOX          |
      | Sent           |
      | Drafts         |
      | Trash          |
      | Work.Projects  |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "Drafts"
    And the output should contain "INBOX"
    And the output should contain "Sent"
    And the output should contain "Trash"
    And the output should contain "Work.Projects"
    And the exit status should be 0

  Scenario: List folders sorted alphabetically
    Given the IMAP server has the following folders:
      | Zebra  |
      | Alpha  |
      | Middle |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the folders should be listed in alphabetical order

  Scenario: Filter folders by regex pattern
    Given the IMAP server has the following folders:
      | INBOX            |
      | INBOX.Subfolder  |
      | Sent             |
      | Trash            |
    When I run `mail-tool list --filter "^INBOX" --config tmp/mail-tool.yml`
    Then the output should contain "INBOX"
    And the output should contain "INBOX.Subfolder"
    And the output should not contain "Sent"
    And the output should not contain "Trash"

  Scenario: List folders when mailbox is empty
    Given the IMAP server has no folders
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "No folders found"

  Scenario: Missing server configuration
    Given no config file exists
    When I run `mail-tool list --config tmp/nonexistent.yml`
    Then the output should contain "server is required"
    And the exit status should be 1

  Scenario: List folders with OAuth2 authentication and valid tokens
    Given a config file with valid OAuth2 credentials
    And a token store with valid tokens for "imap.example.com" and "user@example.com"
    And the IMAP server has the following folders:
      | INBOX |
      | Sent  |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "INBOX"
    And the output should contain "Sent"
    And the exit status should be 0

  Scenario: Missing OAuth2 tokens error
    Given a config file with valid OAuth2 credentials
    And no token store file exists
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "No OAuth2 tokens found"
    And the output should contain "Run 'mail-tool authorize' first"
    And the exit status should be 1
