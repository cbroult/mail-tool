Given("a config file with valid credentials") do
  config_content = {
    "server" => "imap.example.com",
    "port" => 993,
    "username" => "user@example.com",
    "password" => "secret",
    "ssl" => true
  }
  write_file("tmp/mail-tool.yml", YAML.dump(config_content))
end

Given("no config file exists") do
  # The feature references --config tmp/nonexistent.yml, which won't exist
end
