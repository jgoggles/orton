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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121003200847) do

  create_table "game_details", :force => true do |t|
    t.integer  "game_id"
    t.integer  "team_id"
    t.boolean  "is_home"
    t.float    "spread"
    t.integer  "yards_gained"
    t.integer  "yards_allowed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "score"
    t.float    "expected_score"
    t.float    "expected_spread"
    t.string   "su_record"
    t.string   "ats_record"
    t.string   "confidence"
    t.boolean  "pick"
    t.integer  "result"
    t.float    "sos"
    t.float    "pt_diff_score"
    t.float    "ypp_score"
    t.float    "f_c_score"
    t.float    "sag_score"
    t.float    "srs_score"
    t.float    "opening_line"
    t.float    "bet_percent"
    t.integer  "ans"
    t.integer  "dvoa"
    t.float    "off_pass_eff"
    t.integer  "off_pass_eff_rank"
    t.float    "def_pass_eff"
    t.integer  "def_pass_eff_rank"
    t.float    "off_run_eff"
    t.integer  "off_run_eff_rank"
    t.float    "def_run_eff"
    t.integer  "def_run_eff_rank"
    t.float    "off_fumble_rate"
    t.integer  "off_fumble_rate_rank"
    t.float    "def_fumble_rate"
    t.integer  "def_fumble_rate_rank"
    t.float    "off_int_rate"
    t.integer  "off_int_rate_rank"
    t.float    "def_int_rate"
    t.integer  "def_int_rate_rank"
    t.float    "off_penalty_rate"
    t.integer  "off_penalty_rate_rank"
    t.float    "off_scoring"
    t.float    "def_scoring"
    t.integer  "off_scoring_rank"
    t.integer  "def_scoring_rank"
    t.float    "off_scoring_sd"
    t.float    "def_scoring_sd"
    t.float    "off_pass_eff_sd"
    t.float    "def_pass_eff_sd"
    t.float    "off_run_eff_sd"
    t.float    "def_run_eff_sd"
    t.float    "off_fumble_rate_sd"
    t.float    "def_fumble_rate_sd"
    t.float    "off_int_rate_sd"
    t.float    "def_int_rate_sd"
    t.float    "off_penalty_rate_sd"
    t.float    "qb_sacked"
    t.float    "qb_sacked_sd"
    t.float    "qb_sacked_rank"
    t.float    "qb_sacks"
    t.float    "qb_sacks_sd"
    t.float    "qb_sacks_rank"
    t.float    "o_pass"
    t.float    "o_run"
    t.float    "o_int"
    t.float    "o_fum"
    t.float    "d_pass"
    t.float    "d_run"
    t.float    "pen_rate"
  end

  create_table "games", :force => true do |t|
    t.datetime "date"
    t.integer  "week_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "week_name"
    t.text     "notes"
  end

  create_table "picks", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "spread"
    t.integer  "result"
    t.integer  "game_id"
    t.integer  "team_id"
    t.float    "spread_diff"
  end

  create_table "picks_5", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "spread"
    t.integer  "result"
    t.integer  "game_id"
    t.integer  "team_id"
    t.float    "spread_diff"
  end

  create_table "teams", :force => true do |t|
    t.string   "city"
    t.string   "nickname"
    t.integer  "league_id"
    t.integer  "conference_id"
    t.integer  "division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weeks", :force => true do |t|
    t.integer  "name"
    t.integer  "year_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wins"
    t.integer  "losses"
    t.integer  "pushes"
  end

  create_table "years", :force => true do |t|
    t.integer  "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
