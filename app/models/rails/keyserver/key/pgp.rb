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

        Engine.config.uid_email_1   = "notifications-noreply@example.com"
        Engine.config.uid_name_1    = "Rails Notifications"
        Engine.config.uid_comment_1 = "for system notifications"

        Engine.config.uid_email_2   = "security.team@example.com"
        Engine.config.uid_name_2    = "Rails Security"
        Engine.config.uid_comment_2 = "for security advisories"

        def url
          RK::Engine.routes.url_helpers.api_v1_key_url(
            "#{fingerprint}.#{RK::Key::PGP.extension}",
            host: Engine.config.key_host || "localhost",
          )
        end

        def derive_metadata_if_empty
          # jsons usually has 2 items. Which one to use?
          # Match keyid? fingerprint? grip? TODO: match by grip
          # TODO: or, use the one with nil primary key grip?
          # or. just pick one, doesn't matter???
          if metadata.empty?
            jsons = derive_rnp_jsons
            primary_jsons = jsons.select { |j| j["primary key grip"].nil? }
            primary_secret_json = primary_jsons.detect { |j| j["secret key"]["present"] }
            primary_public_json = primary_jsons.detect { |j| j["public key"]["present"] }

            if primary_secret_json
              json = primary_secret_json
              if primary_public_json
                json["public key"] = primary_public_json["public key"]
              end
            else
              json = primary_public_json
            end

            update_column(:metadata, json)
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
          userid.match(/<(.*@.*)>/)[1] if userid
        end

        def first?
          self.class.activated.first.id == id
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

        def active?
          !expires? ||
            first? &&
              expiry_date > Time.now &&
              Time.now > activation_date
        end
        alias active active?

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
          def build_rnp
            Rnp.new
          end

          attr_reader :rnp

          # TODO: spec it
          def build_rnp_and_load_keys(homedir = Rnp.default_homedir)
            homedir_info = ::Rnp.homedir_info(homedir)
            public_info, secret_info = homedir_info.values_at(:public, :secret)

            rnp = Rnp.new(public_info[:format], secret_info[:format])

            [public_info, secret_info].each do |keyring_info|
              input = ::Rnp::Input.from_path(keyring_info[:path])
              rnp.load_keys(format: keyring_info[:format], input: input)
            end

            rnp
          end

          # Load into default RNP instance as well as to a new RNP
          # instance just to differentiate between imported ones from
          # existing ones.
          # TODO: spec it
          def load_key_string(key_string)
            rnp = Rnp.new
            rnp.load_keys(
              format: "GPG",
              input: Rnp::Input.from_string(key_string),
              public_keys: true,
              secret_keys: true,
            )

            rnp
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

          # Expiration means the *duration*, not the actual point in
          # time.
          # Use +key_expiration_time(rnp_key)+ for that purpose.
          def key_validity_seconds(rnp_key)
            rnp_key.json["expiration"]
          end
          private :key_validity_seconds

          def key_creation_time(rnp_key)
            Time.at(rnp_key.json["creation time"])
          end
          private :key_creation_time

          # +key_expiration_time+ is the actual point in time.
          # NOTE: This is different from the terminology used in RFC4880.
          # They use "expiration time" as the "validity period".
          def key_expiration_time(rnp_key)
            Time.at(key_creation_time(rnp_key) + key_validity_seconds(rnp_key))
          end
          private :key_expiration_time

          def key_expired?(rnp_key)
            key_expiration_time(rnp_key) != 0 &&
              key_expiration_time(rnp_key) > Time.now
          end
          private :key_expired?

          # Generate params for #create
          def creation_params(raw:, activation_date:, metadata:)
            {
              private:          raw.secret_key_present? ? raw.secret_key_data : nil,
              public:           raw.public_key_present? ? raw.public_key_data : nil,
              activation_date:  activation_date,
              metadata:         metadata,
              primary_key_grip: metadata["primary key grip"],
              grip:             metadata["grip"],
              fingerprint:      metadata["fingerprint"],
            }.reject { |_k, v| v.nil? }
          end
          private :creation_params

          # Generate a primary key and a corresponding subkey, and return the
          # primary key.
          # URL:
          # http://security.stackexchange.com/questions/31594/what-is-a-good-general-purpose-gnupg-key-setup
          def generate_new_key(
            email: Engine.config.uid_email_1,
            creation_date: Time.now
          )
            rnp = Rnp.new
            generated = rnp.generate_key(
              default_key_params(email: email, creation_date: creation_date),
            )

            key_records = %i[primary sub].map do |key_type|
              raw           = generated[key_type]
              metadata      = raw.json
              creation_hash = creation_params(
                raw: raw, activation_date: creation_date, metadata: metadata,
              )

              RK::Key::PGP.create(creation_hash)
            end

            key_records.first
          rescue StandardError
            warn $!.message
            warn "error: #{$ERROR_INFO.pretty_inspect}"
            warn "error message: #{$ERROR_INFO.message.pretty_inspect}"
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

          # Options available in the GPG Manual:
          # https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html#Unattended-GPG-key-generation
          # Note: in Key-Usage "cert" is always enabled and not specified
          # First UID
          #
          # This key follows the Apple/Microsoft PGP key format where the
          # - primary key is for SC (sign, certify)
          # - subkey is for E (encrypton)
          # NOTE: creation_date has to be a +DateTime+/+Time+/+Date+
          def default_key_params(email: Engine.config.uid_email_1, creation_date:)
            case creation_date
            when DateTime, Time, Date then creation_date
            else raise ArgumentError,
                       "creation_date: has to be a DateTime/Time/Date"
            end

            # 1 year expiry as default
            expiry_date = creation_date + 1.year
            # expiry_date = creation_date + 365 * 60 * 60 * 24

            {
              primary: {
                type: "RSA",
                length: 4096,
                userid: "#{Engine.config.uid_name_1}#{email.present? ? " <#{email}>" : ''} #{Engine.config.uid_comment_1}".strip,
                usage: [:sign],
                expiration: date_format(expiry_date),
                # These are the ruby-rnp defaults:
                # preferences: { 'ciphers' => %w[AES256 AES192 AES128 TRIPLEDES],
                #                'hashes' => %w[SHA256 SHA384 SHA512 SHA224 SHA1],
                #                'compression' => %w[ZLIB BZip2 ZIP Uncompressed] },
                preferences: { "ciphers" => %w[AES256 AES192 AES128 CAST5],
                               "hashes" => %w[SHA512 SHA384 SHA256 SHA224],
                               "compression" => %w[ZLIB BZip2 ZIP Uncompressed] },
              },
              sub: {
                type: "RSA",
                length: 4096,
                usage: [:encrypt],
              },
            }
          end
        end
      end
    end
  end
end
