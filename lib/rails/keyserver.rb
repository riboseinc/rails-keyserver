# frozen_string_literal: true

require "rails/keyserver/engine"
require "activeuuid"
require "pp"
require "active_model_serializers"
require "gpgme"
require "rnp"
# require "mail-gpg"
require "attr_encrypted"
# require "graphql"

module Rails
  module Keyserver
    # Your code goes here...
  end
end

RK = Rails::Keyserver # development use? No, production use, too!
