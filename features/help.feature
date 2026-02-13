Feature: CLI help
  As a mail-tool user
  I want to see help information for available commands
  So that I know how to use the tool

  Scenario: General help lists available commands
    When I run `mail-tool help`
    Then the output should contain "mail-tool help"
    And the output should contain "mail-tool authorize"
    And the output should contain "mail-tool list"
    And the output should contain "mail-tool rename PATTERN REPLACEMENT"
    And the exit status should be 0

  Scenario: General help shows global options
    When I run `mail-tool help`
    Then the output should contain "--server"
    And the output should contain "--port"
    And the output should contain "--username"
    And the output should contain "--password"
    And the output should contain "--ssl"
    And the output should contain "--config"
    And the output should contain "--token-store"

  Scenario: List command help shows usage and options
    When I run `mail-tool help list`
    Then the output should contain "mail-tool list"
    And the output should contain "--filter"
    And the output should contain "Filter folders by regex pattern"
    And the exit status should be 0

  Scenario: Rename command help shows usage and options
    When I run `mail-tool help rename`
    Then the output should contain "mail-tool rename PATTERN REPLACEMENT"
    And the output should contain "--dry-run"
    And the output should contain "--yes"
    And the output should contain "Rename folders matching PATTERN"
    And the exit status should be 0

  Scenario: Authorize command help shows usage
    When I run `mail-tool help authorize`
    Then the output should contain "mail-tool authorize"
    And the output should contain "Authorize with OAuth2 provider"
    And the exit status should be 0

  Scenario: Direct invocation works without Bundler env
    Given an unbundled environment
    When I run `mail-tool help`
    Then the output should contain "mail-tool help"
    And the exit status should be 0

  Scenario: Help for unknown command
    When I run `mail-tool help nonexistent`
    Then the output should contain "Could not find command"
    And the exit status should be 1
