# frozen_string_literal: true

require "rspec/core/rake_task"
require "cucumber/rake/task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features)
RuboCop::RakeTask.new(:rubocop)

desc "Check for vulnerable gems"
task :audit do
  require "bundler/audit/cli"
  Bundler::Audit::Database.update!(quiet: true)
  Bundler::Audit::CLI.start(["check"])
end

desc "Run all static analysis"
task lint: %i[rubocop audit]

task default: %i[spec features lint]
