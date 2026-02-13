Then("the folders should be listed in alphabetical order") do
  lines = last_command_started.output.strip.lines.map(&:strip).reject(&:empty?)
  folder_lines = lines.reject { |l| l.start_with?("---") || l.include?("Folder") && l.include?("Attributes") }
  expect(folder_lines).to eq(folder_lines.sort)
end
