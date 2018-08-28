module Rails
  module Keyserver
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Keyserver
      engine_name "rails_keyserver"

      class << self
        def configure
          yield self
        end

        attr_accessor :uid_name_1
        attr_accessor :uid_email_1
        attr_accessor :uid_comment_1
        attr_accessor :uid_name_2
        attr_accessor :uid_email_2
        attr_accessor :uid_comment_2
        attr_accessor :key_host
        attr_accessor :encryption_key
      end

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot, dir: "spec/factories"
      end

      config.after_initialize do
      end

      # URL:
      # https://blog.pivotal.io/labs/labs/leave-your-migrations-in-your-rails-engines
      initializer :append_migrations do |app|
        unless app.root.to_s.match? root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
