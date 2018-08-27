# frozen_string_literal: true

module Rails::Keyserver
  RSpec.describe Key, type: :model do
    describe "#private" do
      it "is present" do
        pgpkey = FactoryBot.create :rails_keyserver_key_pgp
        expect(pgpkey.private).not_to be_nil
      end

      it "does not have to be present" do
        pgpkey = FactoryBot.create :rails_keyserver_key_pgp
        pgpkey.private = nil
        expect(pgpkey).to be_valid
      end
    end

    describe ".fingerprint" do
      before do
        5.times do
          FactoryBot.create :rails_keyserver_key_pgp
        end
      end

      let(:key) { RK::Key::PGP.last }

      let(:fingerprint) { key.fingerprint }

      context "when provided in full length" do
        let(:sample) { fingerprint }

        it "returns something" do
          expect(sample.length).to eq fingerprint.length
          expect(RK::Key.fingerprint(sample)).to_not be_empty
        end
      end

      # Use at least Long Key IDs (at least 64 bits)
      # URL:
      # http://security.stackexchange.com/questions/84280/short-openpgp-key-ids-are-insecure-how-to-configure-gnupg-to-use-long-key-ids-i
      context "when >= 16 in length" do
        let(:sample) { fingerprint[(40 - 16)..-1] }

        it "returns something" do
          expect(sample.length).to be >= 16
          expect(RK::Key::PGP.fingerprint(sample)).to_not be_empty
        end
      end

      context "when < 16 in length" do
        let(:sample) { fingerprint[(40 - 16 + 1)..-1] }

        it "returns empty" do
          expect(sample.length).to be <= 15
          expect(RK::Key.fingerprint(sample)).to be_empty
        end
      end
    end

    xdescribe ".grip" do
      before do
        5.times do
          FactoryBot.create :rails_keyserver_key_pgp
        end
      end

      subject { RK::Key.last }

      its(:grip) { is_expected.to_not be_nil }
      its(:grip) { is_expected.to be_instance_of String }
    end

    xdescribe ".primary_key_grip" do
      before do
        5.times do
          FactoryBot.create :rails_keyserver_key_pgp
        end
      end

      subject { RK::Key.last }

      # TODO: create keys wih primary key grips
      its(:primary_key_grip) { is_expected.to_not be_nil }
      its(:primary_key_grip) { is_expected.to be_instance_of String }
    end
  end
end
