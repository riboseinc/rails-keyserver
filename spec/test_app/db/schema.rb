# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 201820822000001) do

  create_table "generic_key_owners", id: :uuid, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rails_keyserver_keys", id: :uuid, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "type"
    t.uuid "owner_id"
    t.string "owner_type"
    t.binary "public"
    t.binary "encrypted_private"
    t.binary "encrypted_private_salt"
    t.datetime "activation_date"
    t.text "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary "encrypted_private_iv"
    t.string "primary_key_grip"
    t.string "grip"
    t.string "fingerprint"
    t.datetime "expiration_date"
  end

end
