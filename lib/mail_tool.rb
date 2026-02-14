# frozen_string_literal: true

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

require "mail_tool/configuration"
require "mail_tool/token_store"
require "mail_tool/oauth2_flow"
require "mail_tool/connection"
require "mail_tool/commands/list_folders"
require "mail_tool/commands/rename_folders"
require "mail_tool/cli"
