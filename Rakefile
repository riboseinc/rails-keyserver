begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

# Only generate reports with this environment variable.
if ENV["GENERATE_REPORTS"] == "true"
  require "ci/reporter/rake/rspec"
  task spec: "ci:setup:rspec"
end

require "rdoc/task"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "Rails::Keyserver"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("README.adoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

APP_RAKEFILE = File.expand_path("spec/test_app/Rakefile", __dir__)

load "rails/tasks/engine.rake"
load "rails/tasks/statistics.rake"

Dir.glob("lib/tasks/*.rake").each { |r| load r }

Bundler::GemHelper.install_tasks

require "rspec/core"
require "rspec/core/rake_task"
require "bundler/gem_tasks"

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(spec: "app:db:test:prepare")

task default: :spec
