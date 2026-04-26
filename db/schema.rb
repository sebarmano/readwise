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

ActiveRecord::Schema[8.1].define(version: 2026_04_26_135504) do
  create_table "books", force: :cascade do |t|
    t.string "author"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.string "genre"
    t.text "notes"
    t.integer "rating"
    t.date "read_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "year"
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.string "book_author"
    t.string "book_title"
    t.string "book_type"
    t.datetime "created_at", null: false
    t.integer "outcome_rating"
    t.date "read_at"
    t.text "reason"
    t.integer "recommender_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recommender_id"], name: "index_recommendations_on_recommender_id"
    t.index ["user_id"], name: "index_recommendations_on_user_id"
  end

  create_table "recommenders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.float "fiction_match"
    t.string "name"
    t.float "nonfiction_match"
    t.integer "recommender_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_recommenders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "books", "users"
  add_foreign_key "recommendations", "recommenders"
  add_foreign_key "recommendations", "users"
  add_foreign_key "recommenders", "users"
  add_foreign_key "sessions", "users"
end
