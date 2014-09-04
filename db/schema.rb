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

ActiveRecord::Schema.define(version: 20140904161938) do

  create_table "car_parks", force: true do |t|
    t.string   "id_public"
    t.string   "name"
    t.decimal  "lat"
    t.decimal  "long"
    t.integer  "occupancy"
    t.integer  "capacity"
    t.datetime "data_updated"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "occupancy_percentage",             precision: 16, scale: 3
    t.text     "tariff",               limit: 255
    t.string   "accessibility"
    t.string   "address"
    t.string   "operated_by"
  end

  create_table "community_centres", force: true do |t|
    t.string   "id_public"
    t.string   "name"
    t.string   "address"
    t.string   "post_code"
    t.string   "telephone"
    t.string   "fax"
    t.string   "web"
    t.string   "email"
    t.text     "brief_description"
    t.text     "description"
    t.text     "displayed_hours"
    t.text     "eligibility_information"
    t.decimal  "lat"
    t.decimal  "long"
    t.datetime "data_updated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "school_types", force: true do |t|
    t.integer  "school_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schools", force: true do |t|
    t.string   "id_public"
    t.string   "name"
    t.string   "address"
    t.string   "post_code"
    t.string   "telephone"
    t.string   "fax"
    t.string   "web"
    t.string   "email"
    t.string   "school_type"
    t.string   "head_teacher"
    t.decimal  "lat"
    t.decimal  "long"
    t.datetime "data_updated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
