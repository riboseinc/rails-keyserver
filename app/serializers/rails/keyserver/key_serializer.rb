module Rails
  module Keyserver
    class KeySerializer < ActiveModel::Serializer
      attributes :activation_date,
        :fingerprint
    end
  end
end
