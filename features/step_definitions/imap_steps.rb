Given("the IMAP server has the following folders:") do |table|
  @mock_state["folders"] = table.raw.flatten
  sync_mock!
end

Given("the IMAP server has no folders") do
  @mock_state["folders"] = []
  sync_mock!
end

Given("renaming {string} will fail with {string}") do |folder, error_message|
  @mock_state["rename_errors"][folder] = error_message
  sync_mock!
end

Then("no folders should have been renamed on the server") do
  expect(last_command_started.output).not_to match(/^Renamed \d+ folder/)
end
