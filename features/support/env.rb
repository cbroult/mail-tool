# frozen_string_literal: true

require "aruba/cucumber"

PROJECT_ROOT = File.expand_path("../..", __dir__)

Aruba.configure do |config|
  config.exit_timeout = 10
  config.activate_announcer_on_command_failure = %i[stdout stderr]
  config.command_launcher = :spawn
end

Before do
  prepend_environment_variable("PATH", "#{PROJECT_ROOT}/bin:")
  set_environment_variable("RUBYLIB", "#{PROJECT_ROOT}/lib")
  set_environment_variable("BUNDLE_GEMFILE", "#{PROJECT_ROOT}/Gemfile")
end
