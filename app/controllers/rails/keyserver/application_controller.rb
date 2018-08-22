# frozen_string_literal: true

module Rails
  module Keyserver
    # -
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      before_action :ensure_json_request

      def ensure_json_request
        # Stupid '=='-semantics preventing the following from working:
        # return if %i[json pub pgp].include?(request.format)
        return if [:json, RK::Key::PGP.extension].any? { |i| request.format == i }
        head :not_acceptable
      end
    end
  end
end
