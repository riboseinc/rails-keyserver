# frozen_string_literal: true

require_dependency "rails/keyserver/application_controller"

# -
module Rails
  module Keyserver
    module Api
      module V1
        # -
        class KeysController < Rails::Keyserver::ApplicationController
          before_action :set_composed

          # respond_to :json, RK::Key::PGP.extension

          # Sets scope to only return primary keys, not subkeys.
          # E.g. Use Rib...Key::PGP.where(...) if type == "Rib...Key::PGP"
          def set_composed
            @composed = Rails::Keyserver::Key.descendants.detect do |n|
              n.name == params[:type]
            end || Rails::Keyserver::Key
            @composed = @composed.primary
          end

          def index
            render json: @composed.all
          end

          def show
            raw_fingerprint = params[:fingerprint]
            # Return empty set if fingerprint format invalid
            match           = raw_fingerprint.match(
              /^([a-zA-Z0-9]{16,40})(?:\.#{RK::Key::PGP.extension})?\z/,
            )

            return render json: @composed.none if match.nil?

            key = @composed.fingerprint(match[1]).first
            key = @composed.none if key.nil?

            respond_to do |format|
              format.json do
                render json: key
              end

              # If .pub requested, send key.public as an attachment.
              format.send(RK::Key::PGP.extension) do
                render_options = {}
                render_options[:"#{RK::Key::PGP.extension}"] = key
                render render_options
              end
            end
          end
        end
      end
    end
  end
end
