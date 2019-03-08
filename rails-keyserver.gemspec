# coding: utf-8
# frozen_string_literal: true

# (c) Copyright 2018 Ribose Inc.
#
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Maintain your gem's version:
require "rails/keyserver/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rails-keyserver"
  spec.version     = Rails::Keyserver::VERSION
  spec.authors     = ["Ribose Inc."]
  spec.email       = ["open.source@ribose.com"]
  spec.homepage    = "https://github.com/riboseinc/rails-keyserver"
  spec.summary     = "A generic Rails engine for serving most kinds of keys"
  spec.description = "This key server stores your public & private keys " \
                     'using "attr_encrypted".'
  spec.license     = "MIT"

  spec.metadata["yard.run"] = "yard"

  spec.files            = `git ls-files -z`.split("\x0").grep(%r{^(lib)/})
  spec.extra_rdoc_files = %w[README.adoc CHANGELOG.adoc LICENSE.txt]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.test_files    = Dir["spec/**/*"]

  spec.required_ruby_version = ">= 2.3.4"

  spec.add_dependency "active_model_serializers"
  spec.add_dependency "attr_encrypted"
  spec.add_dependency "gpgme"
  spec.add_dependency "mysql2", "~> 0.3.21"
  spec.add_dependency "rails", "~> 5.1.6"
  spec.add_dependency "rake"
  spec.add_development_dependency "sqlite3"
end
