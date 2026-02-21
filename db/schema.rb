# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_21_200000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "allowed_mime_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: true, null: false
    t.string "mime_type", null: false
    t.datetime "updated_at", null: false
    t.index ["mime_type"], name: "index_allowed_mime_types_on_mime_type", unique: true
  end

  create_table "bans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_bans_on_expires_at"
    t.index ["ip_address"], name: "index_bans_on_ip_address"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "used_by_id"
    t.index ["code"], name: "index_invitations_on_code", unique: true
    t.index ["created_by_id"], name: "index_invitations_on_created_by_id"
    t.index ["used_by_id"], name: "index_invitations_on_used_by_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shared_files", force: :cascade do |t|
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.integer "download_count", default: 0, null: false
    t.string "download_hash", null: false
    t.datetime "expires_at", null: false
    t.bigint "file_size", null: false
    t.integer "max_downloads", default: 5, null: false
    t.string "original_filename", null: false
    t.integer "ttl_hours", default: 24, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["download_hash"], name: "index_shared_files_on_download_hash", unique: true
    t.index ["expires_at"], name: "index_shared_files_on_expires_at"
    t.index ["user_id"], name: "index_shared_files_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "banned", default: false, null: false
    t.datetime "banned_at"
    t.datetime "created_at", null: false
    t.bigint "disk_quota_bytes"
    t.string "email_address", null: false
    t.datetime "last_otp_at"
    t.boolean "otp_required", default: false, null: false
    t.string "otp_secret"
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "nickname"
    t.string "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["external_id"], name: "index_webauthn_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "invitations", "users", column: "created_by_id"
  add_foreign_key "invitations", "users", column: "used_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "shared_files", "users"
  add_foreign_key "webauthn_credentials", "users"
end
