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

ActiveRecord::Schema.define(:version => 20090414113040) do

  create_table "activity_items", :force => true do |t|
    t.integer  "facebook_user_id", :null => false
    t.integer  "assignment_id",    :null => false
    t.string   "sentence",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignments", :force => true do |t|
    t.string   "title"
    t.text     "synopsis"
    t.integer  "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "facebook_user_id",                             :null => false
    t.boolean  "pref_comment_notify",       :default => false
    t.string   "attachment_name"
    t.boolean  "queue_flag",                :default => false
    t.boolean  "published",                 :default => false
    t.string   "prop_language"
    t.string   "prop_language_version"
    t.string   "prop_license"
    t.string   "prop_license_url"
    t.string   "prop_course"
    t.string   "prop_info_url"
    t.string   "prop_estimated_experience"
    t.string   "prop_estimated_time"
    t.string   "prop_estimated_size"
    t.string   "prop_copyright"
  end

  create_table "authorships", :force => true do |t|
    t.integer  "facebook_user_uid",                :null => false
    t.integer  "assignment_id",                    :null => false
    t.integer  "role",              :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "facebook_user_id", :null => false
    t.integer  "assignment_id",    :null => false
  end

  create_table "facebook_users", :force => true do |t|
    t.integer  "uid",                 :limit => 8,                    :null => false
    t.string   "session_key"
    t.string   "session_expires"
    t.datetime "last_access"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "pref_comment_notify",              :default => false
    t.string   "affiliation"
  end

  add_index "facebook_users", ["uid"], :name => "index_facebook_users_on_uid", :unique => true

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                      :default => 0
    t.datetime "created_at",                                 :null => false
    t.string   "rateable_type", :limit => 15,                :null => false
    t.integer  "rateable_id",                 :default => 0, :null => false
    t.integer  "user_id",                     :default => 0, :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

end
