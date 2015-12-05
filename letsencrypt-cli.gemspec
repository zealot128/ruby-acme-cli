# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'letsencrypt/cli/version'

Gem::Specification.new do |spec|
  spec.name          = "letsencrypt-cli"
  spec.version       = Letsencrypt::Cli::VERSION
  spec.authors       = ["Stefan Wienert"]
  spec.email         = ["stwienert@gmail.com"]

  spec.summary       = %q{slim letsencrypt client for quickly authorizing (multiple) domains and issuing certificates}
  spec.homepage      = "https://github.com/zealot28/letsencrypt-cli"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 2.0.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'acme-client'
  spec.add_runtime_dependency 'thor'
  spec.add_runtime_dependency 'colorize'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
