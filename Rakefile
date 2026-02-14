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
  %w[update check].each { |cmd| Bundler::Audit::CLI.start([cmd]) }
end

desc "Run all static analysis"
task lint: %i[rubocop audit]

task default: %i[spec features lint]
