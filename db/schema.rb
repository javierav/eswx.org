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

ActiveRecord::Schema[8.2].define(version: 2026_09_07_100002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "islands", force: :cascade do |t|
    t.string "ine_code", limit: 3, null: false
    t.string "name", null: false
    t.bigint "province_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "weather_territory_id", null: false
    t.index ["ine_code"], name: "index_islands_on_ine_code", unique: true
    t.index ["province_id"], name: "index_islands_on_province_id"
    t.index ["weather_territory_id"], name: "index_islands_on_weather_territory_id"
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "ine_code", limit: 5, null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.bigint "province_id", null: false
    t.bigint "island_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "weather_zone_id", null: false
    t.index ["ine_code"], name: "index_municipalities_on_ine_code", unique: true
    t.index ["island_id"], name: "index_municipalities_on_island_id"
    t.index ["normalized_name"], name: "index_municipalities_on_normalized_name"
    t.index ["province_id"], name: "index_municipalities_on_province_id"
    t.index ["weather_zone_id"], name: "index_municipalities_on_weather_zone_id"
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
    t.string "aemet_code", limit: 2, null: false
    t.index ["aemet_code"], name: "index_regions_on_aemet_code", unique: true
    t.index ["ine_code"], name: "index_regions_on_ine_code", unique: true
  end

  create_table "weather_alerts", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "msg_type", null: false
    t.string "status", null: false
    t.datetime "sent", null: false
    t.string "referenced_identifiers", default: "", null: false
    t.datetime "effective", null: false
    t.datetime "onset", null: false
    t.datetime "expires", null: false
    t.string "severity", null: false
    t.string "level", null: false
    t.string "phenomenon_code", null: false
    t.string "phenomenon_name", null: false
    t.string "parameter"
    t.string "probability"
    t.string "event", null: false
    t.string "headline", null: false
    t.text "description"
    t.text "instruction"
    t.bigint "weather_zone_id", null: false
    t.datetime "superseded_at"
    t.text "raw_cap", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires"], name: "index_weather_alerts_on_expires"
    t.index ["identifier"], name: "index_weather_alerts_on_identifier", unique: true
    t.index ["sent", "superseded_at"], name: "index_weather_alerts_on_sent_and_superseded_at"
    t.index ["weather_zone_id", "phenomenon_code"], name: "index_weather_alerts_on_weather_zone_id_and_phenomenon_code"
    t.index ["weather_zone_id"], name: "index_weather_alerts_on_weather_zone_id"
    t.check_constraint "expires >= onset", name: "weather_alerts_period_check"
    t.check_constraint "level::text = ANY (ARRAY['amarillo'::character varying, 'naranja'::character varying, 'rojo'::character varying]::text[])", name: "weather_alerts_level_check"
    t.check_constraint "msg_type::text = ANY (ARRAY['Alert'::character varying, 'Update'::character varying]::text[])", name: "weather_alerts_msg_type_check"
    t.check_constraint "severity::text = ANY (ARRAY['Moderate'::character varying, 'Severe'::character varying, 'Extreme'::character varying]::text[])", name: "weather_alerts_severity_check"
    t.check_constraint "status::text = ANY (ARRAY['Actual'::character varying, 'Test'::character varying]::text[])", name: "weather_alerts_status_check"
  end

  create_table "weather_territories", force: :cascade do |t|
    t.string "code", limit: 4, null: false
    t.string "name", null: false
    t.bigint "province_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_weather_territories_on_code", unique: true
    t.index ["province_id"], name: "index_weather_territories_on_province_id"
  end

  create_table "weather_zones", force: :cascade do |t|
    t.string "code", limit: 7, null: false
    t.string "name", null: false
    t.boolean "coastal", default: false, null: false
    t.bigint "weather_territory_id", null: false
    t.jsonb "geometry", null: false
    t.text "svg_path", null: false
    t.decimal "min_lat", precision: 8, scale: 5, null: false
    t.decimal "max_lat", precision: 8, scale: 5, null: false
    t.decimal "min_lng", precision: 8, scale: 5, null: false
    t.decimal "max_lng", precision: 8, scale: 5, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_weather_zones_on_code", unique: true
    t.index ["min_lat", "max_lat", "min_lng", "max_lng"], name: "idx_on_min_lat_max_lat_min_lng_max_lng_e7b38179cc"
    t.index ["weather_territory_id", "coastal"], name: "index_weather_zones_on_weather_territory_id_and_coastal"
    t.index ["weather_territory_id"], name: "index_weather_zones_on_weather_territory_id"
  end

  add_foreign_key "islands", "provinces"
  add_foreign_key "islands", "weather_territories"
  add_foreign_key "municipalities", "islands"
  add_foreign_key "municipalities", "provinces"
  add_foreign_key "municipalities", "weather_zones"
  add_foreign_key "provinces", "regions"
  add_foreign_key "weather_alerts", "weather_zones"
  add_foreign_key "weather_territories", "provinces"
  add_foreign_key "weather_zones", "weather_territories"
end
