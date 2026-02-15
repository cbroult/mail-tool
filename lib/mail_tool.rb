# frozen_string_literal: true

require "zeitwerk"
require "thor"
require "net/imap"
require "yaml"

module MailTool
  VERSION = "0.1.0"
  DEFAULT_HIERARCHY_DELIMITER = "/"

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class AuthenticationError < Error; end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("cli" => "CLI", "oauth2_flow" => "OAuth2Flow")
loader.ignore("#{__dir__}/mail_tool/testing")
loader.setup
