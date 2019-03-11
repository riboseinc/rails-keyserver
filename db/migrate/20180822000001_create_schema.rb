# frozen_string_literal: true

# For 'rnp'.
# Only subkeys would have a single primary key grip pointing to the primary
# key's grip.
#
# Key grip can be viewed as the internal ID used by RNP.
# External references should still remain fingerprint.
#
class CreateSchema < ActiveRecord::Migration[5.1]
  def up

    create_table :generic_key_owners, id: :uuid, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end if Rails.env.test? && !table_exists?(:generic_key_owners)

    create_table :rails_keyserver_keys, id: false do |t|
      t.uuid       :id, primary_key: true
      t.string     :type
      # t.references :owner, polymorphic: true
      t.uuid       :owner_id
      t.string     :owner_type
      t.binary     :public
      t.binary     :encrypted_private
      t.binary     :encrypted_private_salt
      t.binary     :encrypted_private_iv
      t.datetime   :activation_date
      t.text       :metadata
      t.string     :primary_key_grip
      t.string     :grip
      t.string     :fingerprint
      t.datetime   :expiration_date
    end unless table_exists?(:rails_keyserver_keys)
  end

  def down
    drop_table :generic_key_owners if table_exists?(:generic_key_owners)
    warn "Table :rails_keyserver_keys left intact"
  end
end

__END__
