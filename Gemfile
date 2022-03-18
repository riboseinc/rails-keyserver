source "https://rubygems.org"

# Declare your gem's dependencies in rails-keyserver.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

# Ensure github repositories are fetched using HTTPS
#
# See:
# https://github.com/huginn/huginn/pull/1763/commits/db4de696b4d71169ca9733ce0fd473a5cdc7c334
# https://github.com/bundler/bundler/issues/4978
#
if Gem::Version.new(Bundler::VERSION) < Gem::Version.new("2")
  git_source(:github) do |repo_name|
    repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
    "https://github.com/#{repo_name}.git"
  end
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
#

gem "bundler"

# Gemfile
group :development do
  gem "pry-rails"
end

group :test do
  gem "ci_reporter_rspec"
  gem "database_cleaner", "~> 1.7.0"
  gem "factory_bot_rails", "~> 4.11.0"
  gem "rspec-its"
  gem "rspec-rails"
  gem "rspec-timecop"
end

# gem "graphql"

gem "mysql-binuuid-rails", github: "kwkwan/mysql-binuuid-rails", branch: "main"

gem "rnp", github: "riboseinc/ruby-rnp"
# gem "sqlite3", group: %i[development test]

# To use a debugger
# gem 'byebug', group: [:development, :test]
