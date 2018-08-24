module Rails
  module Keyserver
    class Key
      class PGPSerializer < KeySerializer
        attributes(
          :active,
          :email,
          :expiry_date,
          :fingerprint,
          :generation_date,
          :key_id,
          :key_size,
          :key_type,
          :url,
          :userid,
        )
      end
    end
  end
end
