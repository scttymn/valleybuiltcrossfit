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

ActiveRecord::Schema[8.1].define(version: 2026_09_18_225631) do
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

  create_table "faqs", force: :cascade do |t|
    t.text "answer"
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "question"
    t.datetime "updated_at", null: false
  end

  create_table "leads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "interest"
    t.string "last_name"
    t.text "notes"
    t.string "phone"
    t.string "pushpress_error"
    t.string "starting_from"
    t.datetime "synced_at"
    t.datetime "updated_at", null: false
    t.string "who"
  end

  create_table "membership_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
  end

  create_table "pillars", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "programs", force: :cascade do |t|
    t.text "blurb"
    t.datetime "created_at", null: false
    t.string "cta"
    t.string "key"
    t.string "kicker"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.text "what"
    t.string "what_title"
    t.text "why"
    t.string "why_title"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "announcement"
    t.string "announcement_url"
    t.boolean "announcement_visible"
    t.string "chat_widget_id"
    t.string "city_state_zip"
    t.integer "class_capacity"
    t.datetime "created_at", null: false
    t.text "dropin_body"
    t.string "dropin_price"
    t.string "dropin_price_note"
    t.string "dropin_title"
    t.string "dropin_url"
    t.text "dropin_why_body"
    t.string "dropin_why_title"
    t.string "email"
    t.string "faq_intro"
    t.text "hero_body"
    t.string "hero_eyebrow"
    t.string "hero_tags"
    t.string "hero_title"
    t.string "hero_title_accent"
    t.integer "image_quality", default: 80
    t.string "instagram_url"
    t.string "lead_notification_email"
    t.decimal "map_latitude", precision: 10, scale: 7
    t.decimal "map_longitude", precision: 10, scale: 7
    t.text "membership_body"
    t.string "membership_rate_note"
    t.string "membership_title"
    t.string "opening_note"
    t.string "phone"
    t.string "programs_intro"
    t.string "pushpress_subdomain"
    t.string "schedule_intro"
    t.string "steps_eyebrow"
    t.string "steps_title"
    t.string "theme_accent"
    t.string "theme_background"
    t.integer "theme_border_width"
    t.string "theme_danger"
    t.string "theme_photo_style"
    t.string "theme_text"
    t.string "uncapped_class_types"
    t.datetime "updated_at", null: false
    t.string "visit_script"
    t.string "visit_title"
  end

  create_table "staff_members", force: :cascade do |t|
    t.text "bio"
    t.string "certification"
    t.string "certification_label"
    t.datetime "created_at", null: false
    t.string "kind", default: "coach", null: false
    t.string "name"
    t.integer "position"
    t.string "role"
    t.datetime "updated_at", null: false
  end

  create_table "steps", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workouts", force: :cascade do |t|
    t.text "beginner"
    t.datetime "created_at", null: false
    t.date "date"
    t.text "intermediate"
    t.text "loads"
    t.string "name"
    t.text "rx"
    t.string "score"
    t.string "source"
    t.text "stimulus"
    t.datetime "updated_at", null: false
    t.string "workout_type"
    t.index ["date"], name: "index_workouts_on_date", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "users"
end
