# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      def mount_keyserver(opts)
        opts[:controllers] ||= {}
        controllers = {
          keys: opts[:controllers][:keys] || "rails/keyserver/keys",
        }

        scope opts[:at].to_s,
          constraints: ->(req) { [:json, RK::Key::PGP.extension].any? { |f| req.format == f } } do
            scope "/pgp" do
              # From the Rails guide:
              # URL: http://guides.rubyonrails.org/routing.html#defining-defaults
              #
              # You cannot override defaults via query parameters - this is for
              # security reasons. The only defaults that can be overridden are dynamic
              # segments via substitution in the URL path.
              #
              resources :keys,
                controller: controllers[:keys],
                param:      :fingerprint,
                only:       %i[index show],
                defaults:   { type: "Rails::Keyserver::Key::PGP" }
            end
          end
      end
    end
  end
end
