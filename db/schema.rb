# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160513142327) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.inet     "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "answers", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "temporary_user_id"
    t.string   "answer_text"
    t.integer  "question_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "place_id"
    t.string   "kind"
    t.integer  "year"
    t.string   "area_name"
    t.string   "code"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "gobierto_cms_attachments", force: :cascade do |t|
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "gobierto_cms_page_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "site_id",                 null: false
  end

  create_table "gobierto_cms_pages", force: :cascade do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "body"
    t.integer  "attachments_count", default: 0
    t.integer  "parent_id"
    t.integer  "position"
    t.datetime "deleted_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "site_id",                       null: false
  end

  add_index "gobierto_cms_pages", ["deleted_at"], name: "index_gobierto_cms_pages_on_deleted_at", using: :btree
  add_index "gobierto_cms_pages", ["parent_id"], name: "index_gobierto_cms_pages_on_parent_id", using: :btree
  add_index "gobierto_cms_pages", ["position"], name: "index_gobierto_cms_pages_on_position", using: :btree
  add_index "gobierto_cms_pages", ["slug"], name: "index_gobierto_cms_pages_on_slug", using: :btree

  create_table "gobierto_participation_comments", force: :cascade do |t|
    t.integer  "user_id",          null: false
    t.text     "body"
    t.integer  "commentable_id",   null: false
    t.string   "commentable_type", null: false
    t.integer  "site_id",          null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "deleted_at"
  end

  add_index "gobierto_participation_comments", ["commentable_id"], name: "index_gobierto_participation_comments_on_commentable_id", using: :btree
  add_index "gobierto_participation_comments", ["commentable_type"], name: "index_gobierto_participation_comments_on_commentable_type", using: :btree
  add_index "gobierto_participation_comments", ["created_at"], name: "index_gobierto_participation_comments_on_created_at", using: :btree
  add_index "gobierto_participation_comments", ["deleted_at"], name: "index_gobierto_participation_comments_on_deleted_at", using: :btree
  add_index "gobierto_participation_comments", ["user_id"], name: "index_gobierto_participation_comments_on_user_id", using: :btree

  create_table "gobierto_participation_consultation_answers", force: :cascade do |t|
    t.integer  "consultation_id",        null: false
    t.string   "answer"
    t.text     "comment"
    t.integer  "user_id",                null: false
    t.integer  "consultation_option_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "site_id",                null: false
    t.datetime "deleted_at"
  end

  add_index "gobierto_participation_consultation_answers", ["consultation_id", "user_id"], name: "gp_consultation_answers_unique_consultation_user", unique: true, using: :btree
  add_index "gobierto_participation_consultation_answers", ["consultation_id"], name: "gp_consultation_answers_consultation_id", using: :btree
  add_index "gobierto_participation_consultation_answers", ["deleted_at"], name: "index_gobierto_participation_consultation_answers_on_deleted_at", using: :btree
  add_index "gobierto_participation_consultation_answers", ["user_id"], name: "gp_consultation_answers_user_id", using: :btree

  create_table "gobierto_participation_consultation_options", force: :cascade do |t|
    t.integer  "consultation_id", null: false
    t.string   "option"
    t.integer  "position"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "site_id",         null: false
    t.datetime "deleted_at"
  end

  add_index "gobierto_participation_consultation_options", ["consultation_id"], name: "gp_consultation_options_consultation_id", using: :btree
  add_index "gobierto_participation_consultation_options", ["deleted_at"], name: "index_gobierto_participation_consultation_options_on_deleted_at", using: :btree

  create_table "gobierto_participation_consultations", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "title"
    t.text     "body"
    t.string   "slug"
    t.integer  "kind",       null: false
    t.datetime "open_until"
    t.integer  "site_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "gobierto_participation_consultations", ["deleted_at"], name: "index_gobierto_participation_consultations_on_deleted_at", using: :btree
  add_index "gobierto_participation_consultations", ["user_id"], name: "index_gobierto_participation_consultations_on_user_id", using: :btree

  create_table "gobierto_participation_ideas", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "title"
    t.text     "body"
    t.string   "slug"
    t.integer  "site_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_index "gobierto_participation_ideas", ["created_at"], name: "index_gobierto_participation_ideas_on_created_at", using: :btree
  add_index "gobierto_participation_ideas", ["deleted_at"], name: "index_gobierto_participation_ideas_on_deleted_at", using: :btree
  add_index "gobierto_participation_ideas", ["user_id"], name: "index_gobierto_participation_ideas_on_user_id", using: :btree

  create_table "sites", force: :cascade do |t|
    t.string   "external_id"
    t.string   "name"
    t.string   "domain"
    t.text     "configuration_data"
    t.string   "location_name"
    t.string   "location_type"
    t.string   "institution_url"
    t.string   "institution_type"
    t.string   "institution_email"
    t.string   "institution_address"
    t.string   "institution_document_number"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "place_id",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "subscriptions", ["place_id"], name: "index_subscriptions_on_place_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_digest"
    t.string   "password_reset_token"
    t.integer  "place_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "verification_token"
    t.boolean  "pro",                  default: false
    t.boolean  "terms_of_service",     default: false
    t.boolean  "admin",                default: false
    t.datetime "deleted_at"
  end

  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["place_id"], name: "index_users_on_place_id", using: :btree

  add_foreign_key "gobierto_participation_comments", "users"
  add_foreign_key "gobierto_participation_consultation_answers", "gobierto_participation_consultation_options", column: "consultation_option_id", name: "fk_gp_consultation_answers_consultation_option_id"
  add_foreign_key "gobierto_participation_consultation_answers", "gobierto_participation_consultations", column: "consultation_id", name: "fk_gp_consultation_answers_consultation_id"
  add_foreign_key "gobierto_participation_consultation_answers", "users", name: "fk_gp_consultation_answers_user_id"
  add_foreign_key "gobierto_participation_consultation_options", "gobierto_participation_consultations", column: "consultation_id", name: "fk_gp_consultation_options_on_consultation_id"
  add_foreign_key "gobierto_participation_consultations", "users"
  add_foreign_key "gobierto_participation_ideas", "users"
  add_foreign_key "subscriptions", "users"
end
