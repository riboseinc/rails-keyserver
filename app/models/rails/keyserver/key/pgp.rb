# frozen_string_literal: true

module Rails
  module Keyserver
    class Key
      class PGP < Rails::Keyserver::Key
        validates :private, presence: true, unless: ->(k) { k.public.present? }
        validates :public, presence: true, unless: ->(k) { k.private.present? }

        def self.extension
          :asc
        end

        # TODO: These defaults belong in somewhere else?
        Engine.config.key_host = nil

        def url
          RK::Engine.routes.url_helpers.api_v1_key_url(
            "#{fingerprint}.#{RK::Key::PGP.extension}",
            host: Engine.config.key_host || "localhost",
          )
        end

        def derive_metadata_if_empty
          derive_metadata if metadata.empty?
        end

        # Pick the one without primar key grip.
        # jsons usually has 2 items. Which one to use?
        # Match keyid? fingerprint? grip? TODO: match by grip
        def derive_metadata
          primary_jsons = derive_rnp_jsons.reject { |j| j["primary key grip"] }
          secret_json, public_json = %w[secret public].map do |k|
            primary_jsons.detect { |j| j["#{k} key"]["present"] }
          end

          json = merge_public_secret_jsons(
            secret_json: secret_json,
            public_json: public_json,
          )

          update_column(:metadata, json)
        end

        def merge_public_secret_jsons(public_json:, secret_json:)
          if secret_json
            secret_json.tap do |j|
              if public_json
                j["public key"] = public_json["public key"]
              end
            end
          else
            public_json
          end
        end

        def save_expiration_date
          super
          derive_metadata_if_empty
          update_column(:expiration_date, expiry_date)
        end

        def save_primary_key_grip
          super
          derive_metadata_if_empty
          update_column(:primary_key_grip, metadata["primary key grip"])
        end

        def save_grip
          super
          derive_metadata_if_empty
          update_column(:grip, metadata["grip"])
        end

        def save_fingerprint
          super
          derive_metadata_if_empty
          update_column(:fingerprint, fingerprint)
        end

        # # Metadata methods
        # # TODO: loops with import_key_string
        # ## Update metadata whenever public key is changed
        # def public=(other)
        #   s = super
        #   self.metadata = raw_key.json
        #   s
        # end

        def key_id
          metadata["keyid"]
        end

        def key_type
          metadata["type"]
        end

        def generation_date
          Time.at(metadata["creation time"])
        end

        def expiry_date
          Time.at(metadata["creation time"] + metadata["expiration"]) if expires?
        end

        def expires?
          metadata["expiration"] != 0
        end

        def expired?
          expires? && expiry_date < Time.now
        end

        def key_size
          metadata["length"]
        end

        def fingerprint
          read_attribute(:fingerprint) || metadata["fingerprint"]
        end

        # TODO?  are we aggregating all user ids of the same key group?
        def userids
          metadata["userids"]
        end

        # TODO? same question as above
        def userid
          userids&.first
        end

        # TODO? same question as above
        def email
          userid.try(:match, / <(.*@.*)>/).try(:[], 1)
        end

        # Return collection of subkeys if +self+ is a primary key.
        # Else, return nil? empty collection?
        def subkeys
          return self.class.none unless primary?

          self.class.where(primary_key_grip: grip)
        end

        def primary?
          primary_key_grip.blank?
        end

        def has_public?
          !public.nil?
        end

        def has_private?
          !private.nil?
        end

        # TODO: make it private.?
        # Internal(?) method to serialize DB key record back to an Rnp key object.
        def derive_rnp_keys
          # First, collect all primary key / subkeys
          # XXX: For Factory-created keys where metadata is incomplete: Don't rely
          # on metadata alone.
          # Export... using....
          # Query all keys for matching grips?
          # 1) export self public & private to Rnp
          [public, private].compact.map do |data|
            rnp = self.class.load_key_string(data)
            self.class.all_keys(rnp)
          end.flatten
        end

        def derive_rnp_jsons
          # 2) Get back metadata for subkey / primary key
          # derive_rnp_keys.map(&:json).uniq { |j| j.values_at('keyid') }
          # XXX: half is public, half is secret
          derive_rnp_keys.map(&:json)
        end

        def all_related_grips
          # 3) query DB for such extra grips
          derive_rnp_json.map do |json|
            ["primary key grip", "subkey grips"].map do |attr|
              json[attr]
            end.compact
          end.flatten.uniq
        end

        # TODO: needed?
        def derive_related_records
          self.class.where(grip: all_related_grips)
        end

        # TODO: needed?
        def derive_related_jsons
          derive_related_records.map(&:metadata)
        end

        class << self
          # TODO: spec it
          def build_rnp_and_load_keys(homedir = Rnp.default_homedir)
            homedir_info = ::Rnp.homedir_info(homedir)
            public_info, secret_info = homedir_info.values_at(:public, :secret)

            Rnp.new(public_info[:format], secret_info[:format]).tap do |rnp|
              [public_info, secret_info].each do |keyring_info|
                input = ::Rnp::Input.from_path(keyring_info[:path])
                rnp.load_keys(format: keyring_info[:format], input: input)
              end
            end
          end

          # Load into default RNP instance as well as to a new RNP
          # instance just to differentiate between imported ones from
          # existing ones.
          # TODO: spec it
          def load_key_string(key_string)
            Rnp.new.tap do |rnp|
              rnp.load_keys(
                format:      "GPG",
                input:       Rnp::Input.from_string(key_string),
                public_keys: true,
                secret_keys: true,
              )
            end
          end

          # Actually save key_string into new record
          def import_key_string(key_string, activation_date: Time.now)
            rnp = load_key_string(key_string)
            all_keys(rnp).map do |raw|
              metadata = raw.json
              creation_hash = creation_params(
                raw: raw, activation_date: activation_date, metadata: metadata,
              )
              create(creation_hash)
            end
          end

          def all_keys(rnp_instance)
            rnp_instance.each_keyid.map { |k| rnp_instance.find_key(keyid: k) }
          end

          # Generate a primary key and a corresponding subkey, and return the
          # primary key.
          # URL:
          # http://security.stackexchange.com/questions/31594/what-is-a-good-general-purpose-gnupg-key-setup
          def generate_new_key(
            name:,
            email: "",
            comment: "",
            creation_date: Time.now,
            key_validity_seconds: 1.year
          )
            generate_new_keys(
              name:                 name,
              email:                email,
              comment:              comment,
              creation_date:        creation_date,
              key_validity_seconds: key_validity_seconds,
            ).first
          end

          # Return a GNUPG-compatible date format for key generation
          #
          # Accepts a +Date+, +Time+ or +DateTime+ object.
          def gnupg_date_format(maybe_datetime)
            datetime = case maybe_datetime
                       when DateTime then maybe_datetime
                       when Time, Date then maybe_datetime.to_datetime
                       else raise ArgumentError,
                                  "datetime: has to be a DateTime/Time/Date"
                       end

            # datetime.utc.iso8601.gsub(/-|:/, '')[0..-6]
            datetime.utc.iso8601.gsub(/-|:/, "")[0..-6]
          end

          # Return an integer representing a point in time
          #
          # Accepts a +Date+, +Time+ or +DateTime+ object.
          def date_format(maybe_datetime)
            datetime = case maybe_datetime
                       when Date then maybe_datetime.to_time
                       when Time, DateTime then maybe_datetime
                       else raise ArgumentError,
                                  "datetime: has to be a DateTime/Time/Date"
                       end
            datetime.to_i
          end

          # Return a hash suitable to be passed to #generate_new_key.
          #
          # 1 year expiry as default
          #
          # Options available in the GPG Manual:
          # https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html#Unattended-GPG-key-generation
          # Note: in Key-Usage "cert" is always enabled and not specified
          # First UID
          #
          # This key follows the Apple/Microsoft PGP key format where the
          # - primary key is for SC (sign, certify)
          # - subkey is for E (encrypton)
          # NOTE: creation_date has to be a +DateTime+/+Time+/+Date+
          def default_key_params(
            name: "",
            email: nil,
            comment: "",
            creation_date: Time.now,
            key_validity_seconds: 1.year
          )
            case creation_date
            when DateTime, Time, Date then creation_date
            else raise ArgumentError,
                       "creation_date: has to be a DateTime/Time/Date"
            end

            expiration_date = if key_validity_seconds.present?
                                date_format(creation_date + key_validity_seconds)
                              end

            userid = "#{name}#{comment.present? ? " (#{comment})" : ''}#{email.present? ? " <#{email}>" : ''}".strip
            key_params(userid: userid, expiration_date: expiration_date)
          end

          private

          # Generate a primary key and a corresponding subkey.
          # URL:
          # http://security.stackexchange.com/questions/31594/what-is-a-good-general-purpose-gnupg-key-setup
          def generate_new_keys(
            name:,
            email: "",
            comment: "",
            creation_date: Time.now,
            key_validity_seconds: 1.year
          )

            generated =
              Rnp.new.generate_key(
                default_key_params(
                  name:                 name,
                  email:                email,
                  comment:              comment,
                  creation_date:        creation_date,
                  key_validity_seconds: key_validity_seconds,
                ),
              )

            %i[primary sub].map do |key_type|
              raw           = generated[key_type]
              creation_hash = creation_params(
                raw: raw, activation_date: creation_date, metadata: raw.json,
              )

              RK::Key::PGP.create(creation_hash)
            end
          end

          def key_params(expiration_date:, userid:)
            {
              primary: {
                type:        "RSA",
                length:      4096,
                userid:      userid,
                usage:       [:sign],
                expiration:  expiration_date,
                # These are the ruby-rnp defaults:
                # preferences: { "ciphers"     => %w[AES256 AES192 AES128 TRIPLEDES],
                #                "hashes"      => %w[SHA256 SHA384 SHA512 SHA224 SHA1],
                #                "compression" => %w[ZLIB BZip2 ZIP Uncompressed] },
                preferences: { "ciphers" => %w[AES256 AES192 AES128 CAST5],
                               "hashes" => %w[SHA512 SHA384 SHA256 SHA224],
                               "compression" => %w[ZLIB BZip2 ZIP Uncompressed] },
              },
              sub:     {
                type:   "RSA",
                length: 4096,
                usage:  [:encrypt],
              },
            }
          end

          # Expiration means the *duration*, not the actual point in
          # time.
          # Use +key_expiration_time(rnp_key)+ for that purpose.
          def key_validity_seconds(rnp_key)
            rnp_key.json["expiration"]
          end

          def key_creation_time(rnp_key)
            Time.at(rnp_key.json["creation time"])
          end

          # +key_expiration_time+ is the actual point in time.
          # NOTE: This is different from the terminology used in RFC4880.
          # They use "expiration time" as the "validity period".
          def key_expiration_time(rnp_key)
            Time.at(key_creation_time(rnp_key) + key_validity_seconds(rnp_key))
          end

          def key_expired?(rnp_key)
            key_expiration_time(rnp_key) != 0 &&
              key_expiration_time(rnp_key) > Time.now
          end

          # Generate params for #create
          def creation_params(raw:, activation_date:, metadata:)
            {
              private:          raw.secret_key_present? ? raw.export_secret : nil,
              public:           raw.public_key_present? ? raw.export_public : nil,
              activation_date:  activation_date,
              metadata:         metadata,
              primary_key_grip: metadata["primary key grip"],
              grip:             metadata["grip"],
              fingerprint:      metadata["fingerprint"],
            }.reject { |_k, v| v.nil? }
          end
        end
      end
    end
  end
end
