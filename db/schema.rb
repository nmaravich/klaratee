# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "db_config"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "company_users", :id => false, :force => true do |t|
    t.string   "company_id"
    t.string   "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "system_settings", :force => true do |t|
    t.integer "company_id"
    t.string  "key"
    t.string  "value"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "remember_token"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "crypted_password",          :limit => 40
    t.string   "password_reset_code",       :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "activation_code",           :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.datetime "deleted_at"
    t.string   "state",                                   :default => "passive"
    t.integer  "creator_id"
    t.integer  "updater_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
