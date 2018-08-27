# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rails::Keyserver::Key::PGP, type: :model do
  let(:pub_key_path_1) { "spec/data/gpg/spec.pub" }
  let(:pub_key_string_1) { File.read pub_key_path_1 }

  let(:pri_key_path_1) { "spec/data/gpg/spec.pri" }
  let(:pri_key_string_1) { File.read pri_key_path_1 }

  let(:key_string) { pub_key_string_1 } # override
  let(:keys) do
    # FactoryBot.create :rails_keyserver_key_pgp
    described_class.import_key_string key_string
  end

  let(:key) { keys.first }

  describe ".setup_gpghome" do
    it "changes ENV['GNUPGHOME']" do
      expect { described_class.setup_gpghome }.to change { ENV["GNUPGHOME"] }
    end

    it "changes ENV['GNUPGHOME'] to a valid file path" do
      ENV["GNUPGHOME"] = "not valid path"
      expect(File).to_not be_readable File.expand_path(ENV["GNUPGHOME"])

      described_class.setup_gpghome
      expect(File).to be_readable File.expand_path(ENV["GNUPGHOME"])
    end

    it "resets ENV['GPG_AGENT_INFO']" do
      ENV["GPG_AGENT_INFO"] = "non-nil"
      expect(ENV["GPG_AGENT_INFO"]).to_not be_blank

      described_class.setup_gpghome
      expect(ENV["GPG_AGENT_INFO"]).to be_blank
    end
  end

  describe ".import_key_string" do
    # let(:key) do
    #   FactoryBot.create :rails_keyserver_key_pgp
    # end

    context "when key is created by GPGME" do
      let(:key_string) { pub_key_string_1 }
      # let(:keypart_to_be_tested) {} # key.private / key.public

      shared_examples_for "all key parts" do
        it "imports without errors" do
          expect { keys }.to_not raise_error
        end

        context "after importing" do
          before do
            keys
          end

          let(:first_imported_key) { keys.first }
          # XXX: What about:
          # let(:key_found_from_imported_keys) { keys.first }

          context "the internal GPGME instance" do
            it "contains 2 keys" do
              expect(keys.length).to eq 2
            end

            it "contains a key with matching fingerprint" do
              expect(keys.first.fingerprint).to eq first_imported_key.fingerprint
            end

            # it "contains a key with matching grip" do
            #   expect(keys.first.grip).to eq first_imported_key.grip
            # end

            it "contains a key with matching keyid" do
              expect(keys.first.key_id).to eq first_imported_key.key_id
            end

            it "contains a key with matching userids" do
              expect(keys.first.userids).to eq first_imported_key.userids
            end
          end

          # TODO: why has secret but no public?
          xit "retains the public part" do
            pp "spec: keys.first"
            # pp keys.first
            # pp "spec: keys.first.json"
            # pp keys.first.json
            pp "spec: keys.first.public"
            pp keys.first.public[0..40]
            expect(keys.first.public).to_not be_nil
          end
        end
      end

      context "for public key" do
        let(:key_string) { pub_key_string_1 }
        let(:keypart_to_be_tested) { key.public }

        it_behaves_like "all key parts"

        context do
          before do
            keys
          end

          it "does not contain the secret part" do
            keys.each do |k|
              expect(k.private).to be_nil
            end
          end
        end
      end

      context "for private key" do
        let(:key_string) { pri_key_string_1 }
        let(:keypart_to_be_tested) { key.private }

        before do
          expect(keypart_to_be_tested).to_not be_nil
        end

        it_behaves_like "all key parts"

        context do
          before do
            keys
          end

          it "retains the secret part" do
            keys.each do |k|
              expect(k).to have_private
            end
          end
        end
      end
    end
  end

  describe ".passfunc" do
    it "has arity of 5" do
      expect(described_class.method(:passfunc).arity).to eq 5
    end
  end

  describe ".progfunc" do
    it "has arity of 5" do
      expect(described_class.method(:progfunc).arity).to eq 5
    end
  end

  describe ".generate_new_key" do
    it "has an arity of 2" do
      # .arity returns -1 for variable params
      # expect(described_class.method(:generate_new_key).arity).to eq 2
      expect(described_class.method(:generate_new_key).parameters.length).to eq 2
    end

    it "has a specific set of optional parameters" do
      %i[
        email
        creation_date
      ].each do |p|
        expect(described_class.method(:generate_new_key).parameters).to include [:key, p]
      end
    end

    subject { described_class.generate_new_key(email: "test") }

    it { is_expected.to be_instance_of described_class }

    it "changes number of keys stored by 2" do
      expect do
        described_class.generate_new_key(email: "test #{rand}")
      end.to change { described_class.count }.by(2)
    end

    it "changes number of keys stored" do
      email = "test #{rand}"
      expect do
        described_class.generate_new_key(email: email)
      end.to change { described_class.all.map(&:fingerprint).length }.by(2)
    end

    it 'increases the number of keys found in "userids"' do
      email = "test #{rand}"
      expect do
        described_class.generate_new_key(email: email)
      end.to change { described_class.all.map(&:metadata).map { |m| m["userids"] }.flatten.compact.uniq.length }.by(1)

      expect do
        described_class.generate_new_key(email: email)
      end.to change { described_class.all.map(&:metadata).map { |m| m["userids"] }.flatten.compact.uniq.length }.by(0)
    end

    xit 'increases the number of keys found in "keys_with_email"' do
      email = "test #{rand}"

      expect do
        described_class.generate_new_key(email: email)
      end.to change { described_class.keys_with_email(email).length }.by(1)

      expect do
        described_class.generate_new_key(email: email)
      end.to change { described_class.keys_with_email(email).length }.by(0)
    end
  end

  describe ".default_key_params" do
    it "has an arity of 2" do
      expect(described_class.method(:default_key_params).parameters.length).to eq 2
    end

    it "has a specific set of required parameters" do
      %i[
        creation_date
      ].each do |p|
        expect(described_class.method(:default_key_params).parameters).to include [:keyreq, p]
      end
    end

    it "has a specific set of optional parameters" do
      %i[
        email
      ].each do |p|
        expect(described_class.method(:default_key_params).parameters).to include [:key, p]
      end
    end

    # it "has a specific set of required parameters" do
    #   %i[
    #     email
    #     creation_date
    #   ].each do |p|
    #     expect(described_class.method(:default_key_params).parameters).to include [:keyreq, p]
    #   end
    # end

    context "when given nonsense as input" do
      it "raises errors" do
        expect { described_class.default_key_params(creation_date: "hello", email: "there") }.to raise_error ArgumentError
      end
    end

    context "when given a good input" do
      let(:result) do
        described_class.default_key_params(creation_date: creation_date, email: "random")
      end

      it "returns a String" do
        expect(result).to be_instance_of String
      end

      context "with extra params" do
        it "returns a String" do
          expect(described_class.default_key_params(creation_date: DateTime.now, email: "there")).to be_instance_of String
        end
      end
    end

    let(:result) do
      if email.nil?
        described_class.default_key_params(creation_date: creation_date)
      else
        described_class.default_key_params(creation_date: creation_date, email: email)
      end
    end

    let(:creation_date) do
      DateTime.now
    end

    let(:email) {}

    %w[
      rando
      local.host
      root@localhost.localdomain
      system@rails.com
    ].each do |e|
      context "with different emails" do
        let(:email) { e }

        it "(#{e}) would contain it" do
          expect(result).to match(/Name-Email:\s*#{e}/)
        end
      end
    end

    [
      Time.now,
      Time.now + 100.years,
      Time.now - 100.years,
      Time.now - 1337.months,
    ].each do |d|
      context "with different creation_date (#{d})" do
        let(:creation_date) { d }
        let(:creation_date_string) { creation_date.utc.iso8601.gsub(/-|:/, "")[0..-6] }

        it "would contain it (#{d.utc.iso8601.gsub(/-|:/, '')[0..-6]})" do
          expect(result).to match /Creation-Date:\s*#{creation_date_string}/
        end

        it "would contain a corresponding expiration time (#{(d + 1.year).utc.iso8601.gsub(/-|:/, '')[0..-6]})" do
          expect(result).to match(/#{(creation_date + 1.year).utc.iso8601.gsub(/-|:/, "")[0..-6]}/)
        end
      end
    end

    {
      "Name-Real"    => "UID_KEY_NAME_FIRST",
      "Name-Comment" => "UID_KEY_COMMENT_FIRST",
      "Name-Email"   => "UID_KEY_EMAIL_FIRST",
    }.each do |field_name, param_name|
      [
        "sdflkj",
        23,
        Object.new,
        [5, 3, 1],
      ].each do |value|

        context "with a different #{param_name} (#{value})" do
          before do
            stub_const("#{described_class}::#{param_name}", value)
          end

          it "contains it in the #{field_name}" do
            expect(result).to match(/#{field_name}:\s*#{value}/)
          end
        end
      end
    end
  end

  xdescribe ".get_generated_key" do
    it "has an arity of 1" do
      expect(described_class.method(:get_generated_key).parameters.length).to eq 1
    end

    it "receives an optional :email" do
      expect(described_class.method(:get_generated_key).parameters).to include %i[key email]
    end

    let(:result) do
      described_class.get_generated_key(email: "random@random.com")
    end

    before do
      allow(described_class).to receive(:public_key_from_keyring).and_return "hello"
      allow(described_class).to receive(:secret_key_from_keyring).and_return "hello"
    end

    it "gives a Hash" do
      expect(result).to be_a Hash
    end

    it "gives 2 keys" do
      expect(result.keys.length).to eq 2
    end

    it "gives :public" do
      expect(result.keys).to include :public
    end

    it "gives :public as a String" do
      expect(result[:public]).to be_a String
    end

    it "gives :secret" do
      expect(result.keys).to include :secret
    end

    it "gives :secret as a String" do
      expect(result[:secret]).to be_a String
    end
  end

  describe ".public_key_from_keyring" do
    it "has an arity of 1" do
      expect(described_class.method(:public_key_from_keyring).arity).to eq 1
    end

    let(:result) do
      described_class.public_key_from_keyring(email)
    end

    let(:email) { key.email }

    it "returns a String" do
      expect(result).to be_a String
    end

    context "for a non-existent email" do
      let(:email) { key.email + "1" }

      it "raises NoMethodError" do
        expect { result }.to raise_error NoMethodError
      end
    end
  end

  xdescribe ".secret_key_from_keyring" do
    it "has an arity of 1" do
      expect(described_class.method(:secret_key_from_keyring).arity).to eq 1
    end

    let(:email) { key.email }

    let(:result) do
      described_class.generate_new_key(email: email)
      described_class.secret_key_from_keyring(email)
    end

    it "returns a String" do
      expect(result).to be_a String
    end

    context "for a non-existent email" do
      let(:email) { key.email + "1" }
      let(:result) do
        described_class.secret_key_from_keyring(email)
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe ".gnupg_date_format" do
    it "has an arity of 1" do
      expect(described_class.method(:gnupg_date_format).arity).to eq 1
    end

    [
      DateTime.now - 1000.years,
      DateTime.now - 10.months,
      DateTime.now,
      DateTime.now + 10.months,
      DateTime.now + 1000.years,
    ].each do |date|
      it "gives the correct date format for #{date}" do
        expect(described_class.gnupg_date_format(date)).to match(/\d{4}\d{2}\d{2}T\d{2}/)
      end
    end
  end

  describe ".date_format" do
    it "has an arity of 1" do
      expect(described_class.method(:date_format).arity).to eq 1
    end

    [1, "a", [], {}].each do |obj|
      it "raises ArgumentError for #{obj}" do
        expect { described_class.date_format(obj) }.to raise_error ArgumentError
      end
    end

    [DateTime.now, Time.now, Time.now.to_date].each do |date|
      it "succeeds for #{date}" do
        expect { described_class.date_format(date) }.to_not raise_error
      end
    end

    [
      DateTime.now - 1000.years,
      DateTime.now - 10.months,
      DateTime.now,
      DateTime.now + 10.months,
      DateTime.now + 1000.years,
    ].each do |date|
      it "gives the correct return type for #{date}" do
        expect(described_class.date_format(date)).to be_kind_of Integer
      end
    end
  end

  describe ".add_uid_to_key" do
    it "has an arity of 1" do
      expect(described_class.method(:add_uid_to_key).parameters.length).to eq 1
    end

    it "has a specific set of optional parameters" do
      expect(described_class.method(:add_uid_to_key).parameters).to include %i[key email]
    end

    context "with missing :userid" do
      it "raises TypeError" do
        expect { described_class.add_uid_to_key(target_email: "valid@example.com") }.to raise_error ArgumentError
      end
    end

    context "with a random email" do
      it "raises TypeError" do
        expect { described_class.add_uid_to_key(email: "random") }.to raise_error TypeError
      end
    end

    context "with valid params" do
      it "succeeds without errors" do
        expect do
          described_class.add_uid_to_key(
            email: described_class::UID_KEY_EMAIL_FIRST,
          )
        end.to_not raise_error
      end

      it "appears in .userids" do
        # generated_keys = described_class.generate_new_key(
        #   email: described_class::UID_KEY_EMAIL_FIRST,
        # )

        measurement = lambda {
          Set.new(described_class.all.to_a.select do |key|
            key.userids.include?(described_class::UID_KEY_EMAIL_FIRST)
          end)
        }
        additional_name = "Example Addition #{rand}"
        additional_email = "valid@example.com"
        additional_comment = "some comment"
        additional_userid = "#{additional_name} (#{additional_comment}) <#{additional_email}>"
        allow(described_class).to receive(:add_uid_params).and_return(
          "keyedit.prompt" => "adduid",
          "keygen.name" => additional_name,
          "keygen.email" => additional_email,
          "keygen.comment" => additional_comment,
        )

        set1 = measurement.call
        described_class.add_uid_to_key(
          email: described_class::UID_KEY_EMAIL_FIRST,
        )
        set2 = measurement.call

        diff = set2 - set1
        expect(diff).to_not be_empty
        expect(diff.first).to eq additional_userid
      end
    end

    xit "calls :add_uid_editfunc" do
      pending "example runs forever until interrupted"
      expect(described_class).to receive(:add_uid_editfunc).once
      described_class.add_uid_to_key
    end

    xit "sets Thread.current['rk-gpg-editkey-working'] to 'true'" do
      pending "Thread local variables cannot be tested"
      expect { described_class.add_uid_to_key }.to change {
        Thread.current["rk-gpg-editkey-working"]
      }.to true
    end

    it "sets Thread.current['rk-gpg-editkey-working'] to 'true'" do
      expect(Thread.current).to receive(:[]=).with("rk-gpg-editkey-working", true)
      described_class.add_uid_to_key
    end
  end

  describe ".add_uid_editfunc" do

    it "has an arity of 4" do
      expect(described_class.method(:add_uid_editfunc).arity).to eq 4
    end

      # when GPGME::GPGME_STATUS_GET_BOOL
      #   debug_log.puts("# GPGME_STATUS_GET_BOOL")
      #   io = IO.for_fd(fd)
      #   # we always answer yes here
      #   io.puts("Y")
      #   io.flush
      # when GPGME::GPGME_STATUS_GET_LINE,
      #   GPGME::GPGME_STATUS_GET_HIDDEN
      #
      #   debug_log.puts("# GPGME_STATUS_GET_(LINE/HIDDEN)")
      #   debug_log.flush
      #
      #   input = add_uid_params[args]
      #
      #   if args == "keyedit.prompt"
      #     if Thread.current['rk-gpg-editkey-working']
      #       Thread.current['rk-gpg-editkey-working'] = nil
      #     else
      #       input = "quit"
      #     end
      #   end
      #
      #   debug_log.puts(" $ #{args} => typing '#{input}'")
      #   io = IO.for_fd(fd)
      #   io.puts(input)
      #   io.flush

    describe "when :status" do
      {
        GPGME::GPGME_STATUS_GOT_IT          => "# GPGME_STATUS_GOT_IT",
        GPGME::GPGME_STATUS_GOOD_PASSPHRASE => "# GPGME_STATUS_GOOD_PASSPHRASE, command complete",
        GPGME::GPGME_STATUS_EOF             => "# GPGME_STATUS_EOF, exiting now",
        "unknown"                           => "# error: unknown status from GPGME editkey. status(unknown) args(2)",
      }.each do |key, val|
        context "is #{key}" do
          let(:status) { key }
          let(:action) { described_class.add_uid_editfunc(nil, status, 2, 4) }
          it "debug_log.puts(#{val})" do
            expect(described_class.debug_log).to receive(:puts).with(val)
            action
          end

        end
      end
    end

    it "reads from the key" do
      pending "TBI mock IO"
      # fd = IO.sysopen("/dev/tty", "w")
      io = IO.new 2
      # io = IO.for_fd fd

      def io.write stuff
        @buffer ||= ""
        @buffer << stuff
      end

      def io.gets
        @buffer
      end

      described_class.add_uid_editfunc(nil, GPGME::GPGME_STATUS_GET_BOOL, 2, 4)
      expect(io.gets).to eq "Y\n"
    end
  end

  describe ".add_uid_params" do
    it "returns a specific Hash" do
      expect(described_class.add_uid_params).to eq ({
        "keyedit.prompt" => "adduid",
        "keygen.name"    => RK::Key::PGP::UID_KEY_NAME_SECOND,
        "keygen.email"   => RK::Key::PGP::UID_KEY_EMAIL_SECOND,
        "keygen.comment" => RK::Key::PGP::UID_KEY_COMMENT_SECOND,
      })
    end
  end

  describe "#expires?" do
    it "is either true or false" do
      expect(key.expires?).to eq(true).or(eq(false))
    end
  end

  describe "#expired?" do
    it "is either true or false" do
      expect(key.expired?).to eq(true).or(eq(false))
    end

    context "for an expired key" do
      let(:key_string) { File.read "spec/data/gpg/expired.pub" }
      it "is true" do
        expect(key).to be_expired
      end
    end
  end

  describe "#expiry_date" do
    it "is nil if it does not expire" do
      expect(key.expiry_date).to be_nil
    end

    context "when key expires" do
      before do
        allow(key).to receive(:expires?).and_return(true)
        allow(key).to receive(:metadata).and_return(
          key.metadata.merge("expiration time" => 123456),
        )
      end

      it "is not blank" do
        expect(key.expiry_date).to_not be_blank
      end
    end
  end

  describe "#fingerprint" do
    it "is not blank" do
      expect(key.fingerprint).to_not be_blank
    end
  end

  describe "#generation_date" do
    it "is not blank" do
      expect(key.generation_date).to_not be_blank
    end
  end

  describe "#key_id" do
    it "is not blank" do
      expect(key.key_id).to_not be_blank
    end
  end

  describe "#key_size" do
    it "is not blank" do
      expect(key.key_size).to_not be_blank
    end
  end

  describe "#key_type" do
    it "is not blank" do
      expect(key.key_type).to_not be_blank
    end
  end

  describe "#public=" do
    [
      "f" * 32,
      "hello!",
      "😎👋🏾👩‍👧‍👦🐩🐉🍠" * 2000,
    ].each do |rval|

      it "sets #public to (#{rval.truncate(20)})" do
        expect { key.public = rval }.to change { key.public }.to rval
      end
    end
  end

  describe "#userid" do
    it "is not blank" do
      expect(key.userid).to_not be_blank
    end
  end

  describe "#userids" do
    it "is not blank" do
      expect(key.userids).to_not be_blank
    end
  end

  describe "#email" do
    it "is not blank" do
      expect(key.email).to_not be_blank
    end
  end

  describe "#url" do
    it "is the full url to the public key itself" do
      # XXX: url_helpers demand a host: but can't be realistically set!
      # URL: https://github.com/rspec/rspec-rails/issues/1275
      # expect(key.url).to eq RK::Engine.routes.url_helpers.api_v1_key_url "#{key.fingerprint}.asc"
      expect(key.url).to eq "http://localhost/ks/api/v1/pgp/keys/#{key.fingerprint}.asc"
    end
  end

  # - wrong key
  #
  # …
  # - read rails pub & pri
  # - Remove private key once a new key is activated
  # - Change encryption key of the new key when it is encrypted
  # use salt
end
