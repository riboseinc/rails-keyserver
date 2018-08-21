# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Maintain your gem's version:
require "rails/keyserver/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rails-keyserver"
  spec.version     = Rails::Keyserver::VERSION
  spec.authors     = ["Ribose Inc."]
  spec.email       = ["open.source@ribose.com"]
  spec.homepage    = "TODO"
  spec.summary     = "TODO: Summary of Rails::Keyserver."
  spec.description = "TODO: Description of Rails::Keyserver."
  spec.license     = "MIT"

  spec.has_rdoc = 'yard'
  spec.metadata['yard.run'] = 'yard'

  spec.files         = `git ls-files -z`.split("\x0").grep(%r{^(lib)/})
  spec.extra_rdoc_files = %w[README.adoc CHANGELOG.adoc LICENSE.txt]

  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_dependency "rails", "~> 5.1.4"
  spec.add_development_dependency "sqlite3"
end
