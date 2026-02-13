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

Given("a config file with OAuth2 auth type but no oauth2 settings") do
  config_content = {
    "server" => "imap.example.com",
    "port" => 993,
    "username" => "user@example.com",
    "auth_type" => "xoauth2",
    "ssl" => true
  }
  write_file("tmp/mail-tool.yml", YAML.dump(config_content))
end

Given("a config file with valid OAuth2 credentials") do
  @token_store_path = File.join(expand_path("."), "tmp", "test-tokens.yml")
  config_content = {
    "server" => "imap.example.com",
    "port" => 993,
    "username" => "user@example.com",
    "auth_type" => "xoauth2",
    "ssl" => true,
    "token_store" => @token_store_path,
    "oauth2" => {
      "client_id" => "test-client-id",
      "client_secret" => "test-client-secret",
      "authorize_url" => "https://example.com/oauth2/auth",
      "token_url" => "https://example.com/oauth2/token",
      "scope" => "mail-r mail-w"
    }
  }
  write_file("tmp/mail-tool.yml", YAML.dump(config_content))
end

Given("a token store with valid tokens for {string} and {string}") do |server, username|
  key = "#{server}/#{username}"
  token_data = {
    key => {
      "access_token" => "valid-test-token",
      "refresh_token" => "valid-refresh-token",
      "expires_at" => Time.now.to_i + 3600
    }
  }
  write_file("tmp/test-tokens.yml", YAML.dump(token_data))
end

Given("no token store file exists") do
  # token_store path in config points to a non-existent file
end

Given("a config file at the default location with valid credentials") do
  config_content = {
    "server" => "imap.example.com",
    "port" => 993,
    "username" => "user@example.com",
    "password" => "secret",
    "ssl" => true
  }
  fake_home = expand_path(".")
  default_config_path = File.join(".config", "mail-tool", "config.yml")
  write_file(default_config_path, YAML.dump(config_content))
  set_environment_variable("HOME", fake_home)
end

Given("no default config directory exists") do
  fake_home = expand_path(".")
  set_environment_variable("HOME", fake_home)
  # .config/mail-tool/ does not exist in Aruba's working directory
end
