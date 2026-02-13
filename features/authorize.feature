Feature: OAuth2 authorization
  As a mail user with an OAuth2-protected mailbox
  I want to authorize mail-tool to access my account
  So that I can use XOAUTH2 authentication

  Scenario: Authorize command help shows usage
    When I run `mail-tool help authorize`
    Then the output should contain "mail-tool authorize"
    And the output should contain "Authorize with OAuth2 provider"
    And the exit status should be 0

  Scenario: Authorize rejects non-xoauth2 config
    Given a config file with valid credentials
    When I run `mail-tool authorize --config tmp/mail-tool.yml`
    Then the output should contain "auth_type must be 'xoauth2'"
    And the exit status should be 1

  Scenario: Authorize rejects missing oauth2 settings
    Given a config file with OAuth2 auth type but no oauth2 settings
    When I run `mail-tool authorize --config tmp/mail-tool.yml`
    Then the output should contain "oauth2.client_id is required"
    And the exit status should be 1
