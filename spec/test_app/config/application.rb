require_relative "boot"

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
# require "active_job/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"
require "sprockets/railtie"

Bundler.require(*Rails.groups)
require "rails/keyserver"

# For creating differently-named database for different environments!
if ENV["DATABASE_URL"].present?
  ENV["DATABASE_URL"] =
    ENV["DATABASE_URL"].gsub(/placeholder_db/, "keyserver_#{Rails.env}")
end

module TestApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # URL: https://github.com/thoughtbot/factory_girl_rails
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  end
end
