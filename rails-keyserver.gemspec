$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails/keyserver/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "Rails Keyserver"
  s.version     = Rails::Keyserver::VERSION
  s.authors     = ["Ribose Inc"]
  s.email       = ["open.source@ribose.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Rails::Keyserver."
  s.description = "TODO: Description of Rails::Keyserver."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
end
