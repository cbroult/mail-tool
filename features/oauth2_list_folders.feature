Feature: List folders with OAuth2 authentication
  As a mail user with an OAuth2-protected mailbox
  I want to list my IMAP mail folders using XOAUTH2 authentication
  So that I can manage my mailbox without a password

  Scenario: Missing oauth2 settings in config
    Given a config file with OAuth2 auth type but no oauth2 settings
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "oauth2.client_id is required"
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

  Scenario: Missing tokens error
    Given a config file with valid OAuth2 credentials
    And no token store file exists
    And the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool list --config tmp/mail-tool.yml`
    Then the output should contain "No OAuth2 tokens found"
    And the output should contain "Run 'mail-tool authorize' first"
    And the exit status should be 1
