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

ActiveRecord::Schema.define(version: 20140804121540) do

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
  end

end
