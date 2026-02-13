Feature: Rename mail folders
  As a mail user
  I want to batch rename IMAP folders using regex patterns
  So that I can reorganize my mailbox efficiently

  Background:
    Given a config file with valid credentials

  Scenario: Dry-run shows planned renames without executing
    Given the IMAP server has the following folders:
      | OldPrefix.Folder1 |
      | OldPrefix.Folder2 |
      | Unrelated         |
    When I run `mail-tool rename "^OldPrefix\." "NewPrefix." --dry-run --config tmp/mail-tool.yml`
    Then the output should contain "OldPrefix.Folder1 -> NewPrefix.Folder1"
    And the output should contain "OldPrefix.Folder2 -> NewPrefix.Folder2"
    And the output should not contain "Unrelated"
    And no folders should have been renamed on the server

  Scenario: Rename folders with confirmation skipped
    Given the IMAP server has the following folders:
      | Temp.Folder1 |
      | Temp.Folder2 |
      | Keep         |
    When I run `mail-tool rename "^Temp\." "Archive.Temp." --yes --no-dry-run --config tmp/mail-tool.yml`
    Then the output should contain "Temp.Folder1 -> Archive.Temp.Folder1"
    And the output should contain "Temp.Folder2 -> Archive.Temp.Folder2"
    And the output should contain "Renamed 2 folder(s)"
    And the exit status should be 0

  Scenario: Rename with backreferences
    Given the IMAP server has the following folders:
      | Work.Projects |
      | Work.Meetings |
      | Personal      |
    When I run `mail-tool rename "^Work\.(.+)" "Archive.\1" --yes --no-dry-run --config tmp/mail-tool.yml`
    Then the output should contain "Work.Projects -> Archive.Projects"
    And the output should contain "Work.Meetings -> Archive.Meetings"
    And the output should not contain "Personal"

  Scenario: Replace all dots with pipe separators in multi-segment folder names
    Given the IMAP server has the following folders:
      | 00.topic.done        |
      | 01.other.in-progress |
      | 02.simple            |
      | NoDots               |
    When I run `mail-tool rename "\." " | " --dry-run --config tmp/mail-tool.yml`
    Then the output should contain "00.topic.done -> 00 | topic | done"
    And the output should contain "01.other.in-progress -> 01 | other | in-progress"
    And the output should contain "02.simple -> 02 | simple"
    And the output should not contain "NoDots"

  Scenario: Replace dots with pipe separators only in matching prefix
    Given the IMAP server has the following folders:
      | 00.topic.done    |
      | 00.topic.pending |
      | Other.Folder     |
    When I run `mail-tool rename "^(\d+)\.(.+)\.(.+)$" "\1 | \2 | \3" --yes --no-dry-run --config tmp/mail-tool.yml`
    Then the output should contain "00.topic.done -> 00 | topic | done"
    And the output should contain "00.topic.pending -> 00 | topic | pending"
    And the output should not contain "Other.Folder"
    And the output should contain "Renamed 2 folder(s)"

  Scenario: No folders match the pattern
    Given the IMAP server has the following folders:
      | INBOX |
      | Sent  |
    When I run `mail-tool rename "^NonExistent\." "Other." --dry-run --config tmp/mail-tool.yml`
    Then the output should contain "No folders match"

  Scenario: Per-folder error handling continues batch
    Given the IMAP server has the following folders:
      | Move.A |
      | Move.B |
      | Move.C |
    And renaming "Move.B" will fail with "Permission denied"
    When I run `mail-tool rename "^Move\." "Done." --yes --no-dry-run --config tmp/mail-tool.yml`
    Then the output should contain "Move.A -> Done.A"
    And the output should contain "Move.C -> Done.C"
    And the output should contain "Failed to rename Move.B"

  Scenario: Invalid regex pattern
    Given the IMAP server has the following folders:
      | INBOX |
    When I run `mail-tool rename "[invalid" "replacement" --dry-run --config tmp/mail-tool.yml`
    Then the output should contain "Invalid regex"
    And the exit status should be 1
