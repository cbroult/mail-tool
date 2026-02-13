Given("an unbundled environment") do
  original = Bundler.original_env
  ENV.each_key do |key|
    next unless key.start_with?("BUNDLE", "RUBYOPT", "RUBYLIB")
    value = original[key]
    if value && !value.empty?
      set_environment_variable(key, value)
    else
      delete_environment_variable(key)
    end
  end
end

Then("the folders should be listed in alphabetical order") do
  lines = last_command_started.output.strip.lines.map(&:strip).reject(&:empty?)
  folder_lines = lines.reject { |l| l.start_with?("---") || l.include?("Folder") && l.include?("Attributes") }
  expect(folder_lines).to eq(folder_lines.sort)
end
