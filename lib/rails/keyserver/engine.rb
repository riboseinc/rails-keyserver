module Rails
  module Keyserver
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Keyserver
      engine_name "rails_keyserver"

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot, dir: "spec/factories"
      end

      config.after_initialize do
      end

      # URL:
      # https://blog.pivotal.io/labs/labs/leave-your-migrations-in-your-rails-engines
      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
