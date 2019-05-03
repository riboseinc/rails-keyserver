# frozen_string_literal: true

Rails::Keyserver::Engine.routes.draw do
  namespace :api,
    constraints: ->(req) { [:json, RK::Key::PGP.extension].any? { |f| req.format == f } } do
    namespace :v1 do
      scope "/pgp" do
        # From the Rails guide:
        # URL: http://guides.rubyonrails.org/routing.html#defining-defaults
        #
        # You cannot override defaults via query parameters - this is for
        # security reasons. The only defaults that can be overridden are dynamic
        # segments via substitution in the URL path.
        #
        resources :keys,
          param:    :fingerprint,
          only:     %i[index show],
          defaults: { type: "Rails::Keyserver::Key::PGP" }
      end

      # resources :keys, only: %i{show}
    end
  end
end
