# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "mail-tool"
  spec.version       = "0.1.0"
  spec.authors       = ["mail-tool"]
  spec.summary       = "Ruby CLI for IMAP folder management"

  spec.files         = Dir["lib/**/*.rb", "bin/*"]
  spec.bindir        = "bin"
  spec.executables   = ["mail-tool"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "net-imap"
  spec.add_dependency "oauth2"
  spec.add_dependency "thor"
  spec.add_dependency "tty-progressbar"
  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "aruba"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.metadata["rubygems_mfa_required"] = "true"
end
