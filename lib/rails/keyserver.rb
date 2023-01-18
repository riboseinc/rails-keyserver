# frozen_string_literal: true

module Rails
  module Keyserver
  end
end

RK = Rails::Keyserver # development use? No, production use, too!

require "rails/keyserver/engine"
require "rails/keyserver/routes"
require "mysql-binuuid-rails"
require "pp"
require "active_model_serializers"
require "gpgme"
require "rnp"
# require "mail-gpg"
require "attr_encrypted"
# require "graphql"
