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

ActiveRecord::Schema[7.2].define(version: 2025_12_18_000002) do
  create_table "agencies", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_agencies_on_slug", unique: true
  end

  create_table "agency_snapshots", force: :cascade do |t|
    t.integer "agency_id", null: false
    t.date "snapshot_date", null: false
    t.integer "word_count", default: 0
    t.integer "section_count", default: 0
    t.string "checksum_sha256"
    t.text "metrics_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "snapshot_date"], name: "index_agency_snapshots_on_agency_id_and_snapshot_date", unique: true
    t.index ["agency_id"], name: "index_agency_snapshots_on_agency_id"
  end

  add_foreign_key "agency_snapshots", "agencies"
end
