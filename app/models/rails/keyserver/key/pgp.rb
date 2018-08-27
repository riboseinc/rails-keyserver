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

        def url
          # TODO: move to config/initializers
          host = if defined?(CONFIG)
                   CONFIG[:app_host]
                 else
                   "localhost"
                 end

          RK::Engine.routes.url_helpers.api_v1_key_url(
            "#{fingerprint}.#{RK::Key::PGP.extension}",
            host: host,
          )
        end

        def to_gpgkey
          # self.class.gpgkey_from_key_string(self.public)
          @to_gpgkey ||= self.class.gpgkey_from_key_string(private || public).first
        end

        def derive_metadata_if_empty
          if metadata.empty?
            json = to_gpgkey.as_json

            update_column(:metadata, json)
          end
        end

        def save_expiration_date
          super
          derive_metadata_if_empty
          update_column(:expiration_date, expiry_date)
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
          metadata["subkeys"][0]["keyid"]
        end

        def key_type
          GPGME.gpgme_pubkey_algo_name metadata["subkeys"][0]["pubkey_algo"]
        end

        def generation_date
          Time.at(metadata["subkeys"][0]["timestamp"])
        end

        def expiry_date
          # TODO: verify
          if expires?
            read_attribute(:expiration_date) || Time.at(to_gpgkey.expires)
          end
        end

        def expires?
            # puts "will expire...?"
            # pp to_gpgkey
          to_gpgkey.expires?
        end

        def expired?
          # metadata["expired"] != 0
          # expires? && expiry_date < Time.now
          to_gpgkey.expired
        end

        def key_size
          metadata["subkeys"][0]["length"].to_i
        end

        def fingerprint
          # read_attribute(:fingerprint) || metadata["subkeys"][0]["fpr"]
          read_attribute(:fingerprint) || to_gpgkey.fingerprint
        end

        def userids
          metadata["uids"].map { |uid| uid["uid"] }
        end

        def userid
          userids&.first
        end

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
          # TODO: GPGME: meaningful to ask for subkeys?
          # self.class.where(primary_key_grip: grip)
        end

        def primary?
          metadata["subkeys"][0]["fpr"] == fingerprint
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

        # TODO: Move these to config/initializers
        UID_KEY_EMAIL_FIRST    = "notifications-noreply@example.com"
        UID_KEY_NAME_FIRST     = "Rails Notifications"
        UID_KEY_COMMENT_FIRST  = "for system notifications"

        UID_KEY_EMAIL_SECOND   = "security.team@example.com"
        UID_KEY_NAME_SECOND    = "Rails Security"
        UID_KEY_COMMENT_SECOND = "for security advisories"

        # -
        class Fakelog
          def puts(_stuff); end

          def write(_stuff); end

          def flush; end
        end

        class << self

          def debug_log
            @debug_log ||= Fakelog.new
            # $stderr
          end

          # def get_generated_key(email: UID_KEY_EMAIL_FIRST)
          #   {
          #     public: public_key_from_keyring(email),
          #     secret: secret_key_from_keyring(email),
          #   }
          # end

          # URL:
          # https://github.com/ueno/ruby-gpgme/blob/master/examples/genkey.rb
          def progfunc(_hook, what, _type, current, total)
            debug_log.write("#{what}: #{current}/#{total}\r")
            debug_log.flush
          end

          # Return first public key with matching +email+
          #
          # NOTE: "first" assume there are no other keys with the same
          # email
          def public_key_from_keyring(email)
            # puts "pubemail is #{email}"
            # Note: "first" assume there are no other keys with the same email
            public_key = GPGME::Key.find(:public, email).first
            public_key.export(armor: true).to_s
          end

          # Return first private key with matching +email+
          #
          # NOTE: "first" assume there are no other keys with the same
          # email
          def secret_key_from_keyring(email)
            # puts "secemail is #{email}"
            secret_key = GPGME::Key.find(:secret, email).first
            return nil unless secret_key

            # GPGME does not allow exporting of private keys
            # Unsafe:
            # `gpg --export-secret-keys -a #{secret_key.fingerprint}`
            # Doesn't return STDOUT:
            # system('gpg', *(%w[--export-secret-keys -a] << secret_key.fingerprint))
            f = IO.popen(%w[gpg --export-secret-keys -a] << secret_key.fingerprint)
            f.readlines.join
          ensure
            f&.close
          end

          def add_uid_to_key(email: UID_KEY_EMAIL_FIRST)
            ctx = GPGME::Ctx.new(
              progress_callback: method(:progfunc),
              passphrase_callback: method(:passfunc),
            )
            Thread.current["rk-gpg-editkey-working"] = true
            ctx.edit_key(ctx.keys(email).first, method(:add_uid_editfunc))
          end

          # Necessary for editfunc
          def passfunc(_hook, _uid_hint, _passphrase_info, _prev_was_bad, file_descriptor)
            io = IO.for_fd(file_descriptor, "w")
            # Returns empty passphrase
            io.puts("")
            io.flush
          end

          # SECOND UID
          def add_uid_params
            {
              "keyedit.prompt" => "adduid",
              "keygen.name"    => UID_KEY_NAME_SECOND,
              "keygen.email"   => UID_KEY_EMAIL_SECOND,
              "keygen.comment" => UID_KEY_COMMENT_SECOND,
            }
          end

          def add_uid_editfunc(_hook, status, args, file_descriptor)
            # return if fd == "-1"
            case status
            when GPGME::GPGME_STATUS_GET_BOOL
              debug_log.puts("# GPGME_STATUS_GET_BOOL")
              io = IO.for_fd(file_descriptor)
              # we always answer yes here
              io.puts("Y")
              io.flush
            when GPGME::GPGME_STATUS_GET_LINE,
              GPGME::GPGME_STATUS_GET_HIDDEN

              debug_log.puts("# GPGME_STATUS_GET_(LINE/HIDDEN)")
              debug_log.flush

              input = add_uid_params[args]

              if args == "keyedit.prompt"
                if Thread.current["rk-gpg-editkey-working"]
                  Thread.current["rk-gpg-editkey-working"] = nil
                else
                  input = "quit"
                end
              end

              debug_log.puts(" $ #{args} => typing '#{input}'")
              io = IO.for_fd(file_descriptor)
              io.puts(input)
              io.flush
            when GPGME::GPGME_STATUS_GOT_IT
              debug_log.puts("# GPGME_STATUS_GOT_IT")
            when GPGME::GPGME_STATUS_GOOD_PASSPHRASE
              debug_log.puts("# GPGME_STATUS_GOOD_PASSPHRASE, command complete")
            when GPGME::GPGME_STATUS_EOF
              debug_log.puts("# GPGME_STATUS_EOF, exiting now")
            else
              debug_log.puts("# error: unknown status from GPGME editkey. status(#{status}) args(#{args.inspect})")
            end
          end

          # Actually save key_string into new record
          def import_key_string(key_string, activation_date: Time.now)
            # puts "importing yo , #{key_string[0..10]}"
            gpgkey_from_key_string(key_string).map do |raw|
              metadata = raw.as_json
              raw_expiration_date = metadata["subkeys"][0]["expires"]
              expiration_date = raw_expiration_date == 0 ? nil : Time.at(raw_expiration_date)

              # require 'pry'
              # binding.pry
              creation_hash = {
                # TODO:
                private:          secret_key_from_keyring(raw.email),
                public:           public_key_from_keyring(raw.email),
                activation_date:  activation_date,
                expiration_date:  expiration_date,
                metadata:         metadata,
                fingerprint:      raw.fingerprint,
              }.reject { |_k, v| v.nil? }

              create(creation_hash)
            end
          end

          def gpgkey_from_key_string(key_string)
            setup_gpghome
            s = GPGME::Key.import(key_string)
            # pp "imports plzx"
            # pp s.imports
              # require 'pry'
              # binding.pry
            GPGME::Key.find(:secret, s.imports.first.fpr) +
              GPGME::Key.find(:public, s.imports.first.fpr)
          end

          # Expiration means the *duration*, not the actual point in
          # time.
          # Use +key_expiration_time(gpg_key)+ for that purpose.
          def key_validity_seconds(gpg_key)
            gpg_key.as_json["expiration"]
          end
          private :key_validity_seconds

          def key_creation_time(gpg_key)
            Time.at(gpg_key.as_json["creation time"])
          end
          private :key_creation_time

          # +key_expiration_time+ is the actual point in time.
          # NOTE: This is different from the terminology used in RFC4880.
          # They use "expiration time" as the "validity period".
          def key_expiration_time(gpg_key)
            Time.at(key_creation_time(gpg_key) + key_validity_seconds(gpg_key))
          end
          private :key_expiration_time

          def key_expired?(gpg_key)
            key_expiration_time(gpg_key) != 0 &&
              key_expiration_time(gpg_key) > Time.now
          end
          private :key_expired?

          # URL:
          # https://github.com/jkraemer/mail-gpg/blob/8ee91e49bdcff0a59a9952d45bb4f2c23525747d/Rakefile
          def setup_gpghome
            gpghome               = Dir.mktmpdir("rails-keyserver-gpghome")
            ENV["GNUPGHOME"]      = gpghome
            ENV["GPG_AGENT_INFO"] = "" # disable gpg agent

            Rails.logger.info "[rails-keyserver] created temporary GNUPGHOME at #{gpghome}"
            debug_log.puts "[rails-keyserver] created temporary GNUPGHOME at #{gpghome}"
          end

          # URL:
          # http://security.stackexchange.com/questions/31594/what-is-a-good-general-purpose-gnupg-key-setup
          def generate_new_key(
            email: UID_KEY_EMAIL_FIRST,
            creation_date: Time.now
          )
            ctx = GPGME::Ctx.new(
              # progress_callback: method(:progfunc)
              #passphrase_callback: method(:passfunc)
            )
            ctx.genkey(
              default_key_params(email: email, creation_date: creation_date), nil, nil
            )
            activation_date = creation_date
            pubkey = public_key_from_keyring(email)
            seckey = secret_key_from_keyring(email)

            key_records = %i[primary sub].map do |key_type|
              raw           = generated[key_type]
              metadata      = raw.json
              creation_hash = {
                private:          seckey,
                public:           pubkey,
                activation_date:  activation_date,
                metadata:         metadata,
                primary_key_grip: metadata["primary key grip"],
                grip:             metadata["grip"],
                fingerprint:      metadata["fingerprint"],
              }.reject { |_k, v| v.nil? }

              RK::Key::PGP.create(creation_hash)
            end

            # Return the primary key
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
          def default_key_params(email: UID_KEY_EMAIL_FIRST, creation_date:)
            case creation_date
            when DateTime, Time, Date then creation_date
            else raise ArgumentError,
                       "creation_date: has to be a DateTime/Time/Date"
            end

            # 1 year expiry as default
            expiry_date = creation_date + 1.year
            # expiry_date = creation_date + 365 * 60 * 60 * 24

            <<~EOOPTS
              <GnupgKeyParms format="internal">
              Key-Type: RSA
              Key-Length: 4096
              Key-Usage: sign
              Subkey-Type: RSA
              Subkey-Length: 4096
              Subkey-Usage: encrypt
              Name-Real: #{UID_KEY_NAME_FIRST}
              Name-Comment: #{UID_KEY_COMMENT_FIRST}
              Name-Email: #{email}
              Expire-Date: #{gnupg_date_format(expiry_date)}
              Creation-Date: #{gnupg_date_format(creation_date)}
              Preferences: SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
              </GnupgKeyParms>
            EOOPTS
          end
        end
      end
    end
  end
end
