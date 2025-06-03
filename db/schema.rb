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

ActiveRecord::Schema[8.0].define(version: 2025_06_03_121014) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.string "activity_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type"], name: "index_activities_on_activity_type"
    t.index ["company_id", "activity_type", "occurred_at"], name: "index_activities_on_company_type_and_time"
    t.index ["company_id", "occurred_at"], name: "index_activities_on_company_id_and_occurred_at"
    t.index ["company_id"], name: "index_activities_on_company_id"
    t.index ["metadata"], name: "index_activities_on_metadata", using: :gin
    t.index ["occurred_at"], name: "index_activities_on_occurred_at"
    t.index ["user_id", "activity_type"], name: "index_activities_on_user_id_and_activity_type"
    t.index ["user_id"], name: "index_activities_on_user_id"
    t.check_constraint "activity_type::text = ANY (ARRAY['login'::character varying, 'logout'::character varying, 'give_recognition'::character varying, 'receive_recognition'::character varying, 'profile_update'::character varying, 'admin_action'::character varying]::text[])", name: "valid_activity_type"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "activity_tracking_enabled", default: true, null: false
    t.jsonb "activity_tracking_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_tracking_enabled"], name: "index_companies_on_activity_tracking_enabled"
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "role", default: "user", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "email"], name: "index_users_on_company_id_and_email", unique: true
    t.index ["company_id", "role"], name: "index_users_on_company_id_and_role"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activities", "companies"
  add_foreign_key "activities", "users"
  add_foreign_key "users", "companies"
end
