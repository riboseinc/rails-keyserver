# frozen_string_literal: true

module Rails
  module Keyserver
    class Key < ApplicationRecord
      class EncryptionKeyNotFoundException < RuntimeError; end

      include MySQLBinUUID::UUID
      attribute :id, :uuid
      attribute :owner_id, :uuid

      store :metadata, coder: JSON

      # abstract class implementation for STI -- can't be instantiated
      validates :type, presence: true

      # URL:
      # http://stackoverflow.com/questions/16981866/rails-4-validate-uniqueness-with-hash-scope-deprecated
      # validates :fingerprint, uniqueness: { scope: :key_id, allow_blank: false }
      # validates :fingerprint, uniqueness: { scope: :grip, allow_blank: false }
      # TODO: reactivate
      # validates :fingerprint, uniqueness: { allow_blank: false }

      # To be overridden in subclasses
      def save_expiration_date; end
      after_save :save_expiration_date

      # To be overridden in subclasses
      def save_grip; end
      after_save :save_grip

      # To be overridden in subclasses
      def save_primary_key_grip; end
      after_save :save_primary_key_grip

      # To be overridden in subclasses
      def save_fingerprint; end
      after_save :save_fingerprint

      belongs_to :owner, polymorphic: true

      # XXX: key blankness should ideally be checked in attr_encrypted!
      if Engine.config.encryption_key.blank?
        raise EncryptionKeyNotFoundException,
              "Engine.config.encryption_key is blank!"
      end

      attr_encrypted :private,
                     key:  Engine.config.encryption_key,
                     mode: Engine.config.try(:encryption_mode) || :per_attribute_iv

      scope :primary, -> {
        pkg = arel_table[:primary_key_grip]
        where pkg.eq nil
      }

      scope :date_from, ->(given_date) {
        ad = arel_table[:activation_date]
        where ad.gteq given_date
      }

      scope :date_to, ->(given_date) {
        ad = arel_table[:activation_date]
        where ad.lteq given_date
      }

      scope :fresh, -> {
        ad = arel_table[:expiration_date]
        where((ad.gt Time.now).or(ad.eq nil))
      }

      scope :expired, -> {
        not fresh
      }

      # Use at least Long Key IDs (at least 64 bits)
      # URL:
      # http://security.stackexchange.com/questions/84280/short-openpgp-key-ids-are-insecure-how-to-configure-gnupg-to-use-long-key-ids-i
      #
      # Return the key with the given fingerprint (has to be >= 16 chars)
      scope :fingerprint, lambda { |fpr|
        return none if fpr.length <= 15

        k = RK::Key.arel_table
        where(k[:fingerprint].matches("%#{fpr}"))
      }
    end
  end
end
