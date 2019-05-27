# frozen_string_literal: true

require "rails_helper"

# TODO: must be able to render expired keys in both #show and #index

# module Rails::Keyserver::Api::V1
# # public page API for MTCS archive
# # GET JSON
# # /security/pgp_keys?date_from=X&date_to=Y&purpose=mail&sort_by=activation_date&order=desc
# [
#   {
#     public: '===== BEGIN PGP BLOCK ==========.....',
#     key_id: 0x346cb446
#     key_type: rsa
#     expiry_date: '2055/12/12 11:23:45Z+08:00'
#     key_size: 4096/4096
#     fingerprint: 72e5 f8ae da11 7b85 fadb 25a5 83a3 ef8c 346c b446
#     userid: apple product security
#     activation_date: '2055/12/12 11:23:45Z+08:00',
#   }
# ]
#
# # GET JSON /security/pgp_keys
# [
#   {
#     public: '===== BEGIN PGP BLOCK ==========.....',
#     key_id: 0x346cb446
#     key_type: rsa
#     expiry_date: '2055/12/12 11:23:45Z+08:00'
#     key_size: 4096/4096
#     fingerprint: 72e5 f8ae da11 7b85 fadb 25a5 83a3 ef8c 346c b446
#     userid: apple product security
#     activation_date: '2055/12/12 11:23:45Z+08:00',
#   }
# ]
#
# # rails users: public PGP
# # DELETE  JSON /settings/pgp_key
# # POST  PUT  GET JSON /settings/pgp_key
# 200:
# {
#   id: 'slfsjdfdklsj',
#   public: '===== BEGIN PGP BLOCK ==========.....',
#   key_id: 0x346cb446
#   key_type: rsa
#   expiry_date: '2055/12/12 11:23:45Z+08:00'
#   key_size: 4096/4096
#   fingerprint: 72e5 f8ae da11 7b85 fadb 25a5 83a3 ef8c 346c b446
#   userid: apple product security
#   created_at: '2055/12/12 11:23:45Z+08:00',
# }
#
# 422:
# {
#   errors: {
#     format: 'invalid'
#   }
# }
#
# 403:
# {
#   errors: {
#     permission: 'denied'
#   }
# }

RSpec.describe Rails::Keyserver::Api::V1::KeysController, type: :controller do
  routes do
    Rails::Keyserver::Engine.routes
  end

  let(:json) do
    begin
      JSON.parse response.body
    rescue JSON::ParserError
      ""
    end
  end

  let(:req_params) do
    {
      format: "json",
    }.merge(filter_params)
  end

  let(:filter_params) do
    {}
  end

  let(:key_path_1) { "spec/data/gpg/spec.pub" }
  let(:key_string_1) { File.read key_path_1 }

  describe "#show" do
    let(:action) do
      lambda {
        get :show, params: req_params.merge(type: "Rails::Keyserver::Key::PGP")
      }
    end

    context "with a full fingerprint param" do
      context "with .asc extension" do
        let(:filter_params) do
          {
            fingerprint: key.fingerprint,
            format:      "asc",
          }
        end

        it "returns something" do
          expect(response.body).to_not be_empty
        end

        it "returns an ASCII-armoured public key" do
          expect(response.body).to match(/\A-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n/).and match(/-----END PGP PUBLIC KEY BLOCK-----(?:\r\n)?\z/)
        end

        it "returns the exact public key" do
          expect(response.body).to eq key.public
        end

        context "for an expired key" do
          let(:expired_key_path_1) do
            # rubocop:disable Rails/DynamicFindBy
            File.join(
              Gem::Specification.find_by_name("rails-keyserver").full_gem_path,
              "spec/data/gpg/expired.pub",
            )
            # rubocop:enable Rails/DynamicFindBy
          end
          let(:key_string) { File.read expired_key_path_1 }

          before do
            expect(key).to be_expired
          end

          it "returns something" do
            # puts 'responsseee'
            # pp response.body
            expect(response.body).to_not be_empty
          end

          it "returns the exact public key" do
            expect(response.body).to eq key.public
          end
        end
      end

      let(:key) do
        keys.first
      end

      let(:key_string) do
        key_string_1
      end

      let(:keys) do
        RK::Key::PGP.import_key_string key_string
      end

      let(:filter_params) do
        {
          fingerprint: key.fingerprint,
        }
      end

      before do
        keys
        expect(RK::Key.all.length).to be > 0
        action[]
      end

      it "returns the JSON of the key" do
        expect(json).to_not be_empty
      end

      it "returns the JSON of only one key" do
        expect(json).to be_a Hash
        expect(json).to_not be_a Array
      end

      expected_attributes =
        %w[
          activation_date
          email
          expiry_date
          fingerprint
          generation_date
          key_id
          key_size
          key_type
          userid
        ]

      expected_attributes.each do |attr|
        it "contains `#{attr}'" do
          expect(json.keys).to include attr
        end
      end

      it "contains nothing else" do
        expect(json.keys.length).to eq expected_attributes.length
      end
    end

    # Use at least Long Key IDs (at least 64 bits)
    # URL:
    # http://security.stackexchange.com/questions/84280/short-openpgp-key-ids-are-insecure-how-to-configure-gnupg-to-use-long-key-ids-i
    #
    [
      16, 32, 40
    ].each do |len|
      context "with a partial fingerprint param (length: #{len})" do
        let(:keys) do
          RK::Key::PGP.import_key_string key_string_1
        end

        let(:key) { keys.first }

        let(:filter_params) do
          {
            fingerprint: key.fingerprint[(40 - len)..-1],
          }
        end

        before do
          expect(filter_params[:fingerprint].length).to eq len
          action[]
        end

        it "returns the JSON of the key" do
          expect(json).to_not be_empty
        end
      end
    end

    [
      1, 2, 4, 8, 15
    ].each do |len|
      context "with a partial fingerprint param that is too short (length: #{len})" do
        let(:keys) do
          RK::Key::PGP.import_key_string key_string_1
        end

        let(:key) { keys.first }

        let(:filter_params) do
          {
            fingerprint: key.fingerprint[(40 - len)..-1],
          }
        end

        before do
          expect(filter_params[:fingerprint].length).to eq len
          action[]
        end

        it "returns empty" do
          expect(json).to be_empty
        end
      end
    end

    context "with an empty fingerprint param (length: 0)" do
      let(:keys) do
        RK::Key::PGP.import_key_string key_string_1
      end

      let(:key) { keys.first }

      let(:filter_params) do
        {
          fingerprint: "",
        }
      end

      before do
        action[]
      end

      it "returns an array of keys" do
        expect(json).to be_a Array
      end

      it "returns an empty object" do
        expect(json).to be_empty
      end
    end

    context "with a non-existent fingerprint param" do
      let(:keys) do
        RK::Key::PGP.import_key_string key_string_1
      end

      let(:key) { keys.first }

      let(:filter_params) do
        {
          fingerprint: key.fingerprint[0..-2].reverse,
        }
      end

      before do
        action[]
      end

      it "returns an empty JSON" do
        expect(json).to be_empty
      end
    end
  end

  describe "#index" do
    context "with a random :type" do
      before do
        action[]
      end

      %i[
        Object
        asdf
        345235
        =
        false
        true
        0
        -1
        +
        &
        ">
      ].each do |type|
        context type.to_s do
          let(:filter_params) do
            {
              type: type,
            }
          end

          it "doesn't modify request.params[:type]" do
            expect(request.params[:type]).to eq "Rails::Keyserver::Key::PGP"
          end

          it "returns nothing" do
            expect(json).to be_empty
          end

          it "is OK…" do
            expect(response).to be_success
          end
        end
      end
    end

    context "when format is HTML" do
      before do
        action[]
      end

      let(:req_params) do
        {
          format: "html",
        }
      end

      it "returns nothing" do
        expect(response.body.strip).to be_empty
      end

      it "is not OK" do
        expect(response).to_not be_success
      end
    end

    let(:action) do
      lambda {
        get :index, params: req_params.merge(type: "Rails::Keyserver::Key::PGP")
      }
    end

    it "is OK" do
      expect(response).to be_success
    end

    context "when keys exist" do
      before do
        1.times { RK::Key::PGP.import_key_string key_string_1 }
        action[]
      end

      it "is OK" do
        expect(response).to be_success
      end

      it "returns keys" do
        expect(response.body).to_not be_empty
      end

      describe "the JSON" do
        it "returns only one record" do
          expect(json.length).to eq 1
        end

        expected_attributes =
          %w[
            activation_date
            email
            expiry_date
            fingerprint
            generation_date
            key_id
            key_size
            key_type
            userid
          ]

        expected_attributes.each do |attr|
          it "contains '#{attr}'" do
            expect(json.first).to include attr
          end

          it "contains nothing else" do
            expect(json.first.keys.length).to eq expected_attributes.length
          end
        end
      end
    end
  end

  {
    destroy: :delete,
    create:  :post,
    new:     :get,
    update:  :put,
  }.each do |action, method|
    describe "##{action}" do
      let(:fn) do
        lambda {
          send method, action, params: req_params
        }
      end

      it "has no such route" do
        expect(fn).to raise_error ActionController::UrlGenerationError
      end
    end
  end
end
# end
