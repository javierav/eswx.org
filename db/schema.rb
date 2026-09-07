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

ActiveRecord::Schema[8.2].define(version: 2026_09_07_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "islands", force: :cascade do |t|
    t.string "ine_code", limit: 3, null: false
    t.string "name", null: false
    t.bigint "province_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ine_code"], name: "index_islands_on_ine_code", unique: true
    t.index ["province_id"], name: "index_islands_on_province_id"
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "ine_code", limit: 5, null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.bigint "province_id", null: false
    t.bigint "island_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ine_code"], name: "index_municipalities_on_ine_code", unique: true
    t.index ["island_id"], name: "index_municipalities_on_island_id"
    t.index ["normalized_name"], name: "index_municipalities_on_normalized_name"
    t.index ["province_id"], name: "index_municipalities_on_province_id"
  end

  create_table "provinces", force: :cascade do |t|
    t.string "ine_code", limit: 2, null: false
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ine_code"], name: "index_provinces_on_ine_code", unique: true
    t.index ["region_id"], name: "index_provinces_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "ine_code", limit: 2, null: false
    t.string "name", null: false
    t.string "time_zone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ine_code"], name: "index_regions_on_ine_code", unique: true
  end

  add_foreign_key "islands", "provinces"
  add_foreign_key "municipalities", "islands"
  add_foreign_key "municipalities", "provinces"
  add_foreign_key "provinces", "regions"
end
