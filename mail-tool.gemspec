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
  spec.add_dependency "thor", "~> 1.5"

  spec.add_development_dependency "aruba", "~> 2.3"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "cucumber", "~> 9.0"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.75"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 3.5"
  spec.metadata["rubygems_mfa_required"] = "true"
end
