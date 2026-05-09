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

ActiveRecord::Schema[7.2].define(version: 2026_05_09_094125) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.datetime "created_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
    t.check_constraint "blocker_id <> blocked_id", name: "blocks_no_self_block"
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author"
    t.string "isbn"
    t.string "cover_url"
    t.date "published_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author"], name: "index_books_on_author", opclass: :gin_trgm_ops, using: :gin
    t.index ["isbn"], name: "index_books_on_isbn", unique: true, where: "(isbn IS NOT NULL)"
    t.index ["title"], name: "index_books_on_title", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "created_at"], name: "index_comments_on_post_alive", where: "(deleted_at IS NULL)"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform", "token"], name: "index_devices_on_platform_and_token", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followee_id", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followee_id", "status"], name: "index_follows_on_followee_id_and_status"
    t.index ["followee_id"], name: "index_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_follows_on_follower_id_and_followee_id", unique: true
    t.index ["follower_id", "status"], name: "index_follows_on_follower_id_and_status"
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.check_constraint "follower_id <> followee_id", name: "follows_no_self_follow"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genres_on_name", unique: true
  end

  create_table "hashtags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hashtags_on_name", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", null: false
    t.index ["target_type", "target_id"], name: "index_likes_on_target"
    t.index ["user_id", "target_type", "target_id"], name: "index_likes_unique_user_target", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "mutes", force: :cascade do |t|
    t.bigint "muter_id", null: false
    t.bigint "muted_id", null: false
    t.datetime "created_at", null: false
    t.index ["muted_id"], name: "index_mutes_on_muted_id"
    t.index ["muter_id", "muted_id"], name: "index_mutes_on_muter_id_and_muted_id", unique: true
    t.index ["muter_id"], name: "index_mutes_on_muter_id"
    t.check_constraint "muter_id <> muted_id", name: "mutes_no_self_mute"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id", null: false
    t.string "notification_type", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_timeline", order: { created_at: :desc }
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["recipient_id"], name: "index_notifications_unread", where: "(read_at IS NULL)"
    t.index ["target_type", "target_id"], name: "index_notifications_on_target"
  end

  create_table "post_hashtags", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "hashtag_id", null: false
    t.datetime "created_at", null: false
    t.index ["hashtag_id", "post_id"], name: "index_post_hashtags_on_hashtag_id_and_post_id"
    t.index ["hashtag_id"], name: "index_post_hashtags_on_hashtag_id"
    t.index ["post_id", "hashtag_id"], name: "index_post_hashtags_on_post_id_and_hashtag_id", unique: true
    t.index ["post_id"], name: "index_post_hashtags_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_id"
    t.text "body", null: false
    t.tsvector "body_tsv"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_tsv"], name: "index_posts_on_body_tsv", using: :gin
    t.index ["book_id"], name: "index_posts_on_book_id"
    t.index ["created_at", "id"], name: "index_posts_on_alive_timeline", order: :desc, where: "(deleted_at IS NULL)"
    t.index ["user_id", "created_at"], name: "index_posts_on_user_alive_timeline", where: "(deleted_at IS NULL)"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "reposts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.string "repost_type", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.index ["post_id", "created_at"], name: "index_reposts_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_reposts_on_post_id"
    t.index ["user_id", "post_id"], name: "index_reposts_unique_simple", unique: true, where: "((repost_type)::text = 'simple'::text)"
    t.index ["user_id"], name: "index_reposts_on_user_id"
  end

  create_table "search_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "query", null: false
    t.string "category", default: "all", null: false
    t.datetime "executed_at", null: false
    t.datetime "created_at", null: false
    t.index ["user_id", "executed_at"], name: "index_search_histories_on_user_recent", order: { executed_at: :desc }
    t.index ["user_id"], name: "index_search_histories_on_user_id"
  end

  create_table "user_favorite_books", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_user_favorite_books_on_book_id"
    t.index ["user_id", "book_id"], name: "index_user_favorite_books_on_user_id_and_book_id", unique: true
    t.index ["user_id", "position"], name: "index_user_favorite_books_on_user_id_and_position"
    t.index ["user_id"], name: "index_user_favorite_books_on_user_id"
  end

  create_table "user_genres", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.index ["genre_id"], name: "index_user_genres_on_genre_id"
    t.index ["user_id", "genre_id"], name: "index_user_genres_on_user_id_and_genre_id", unique: true
    t.index ["user_id"], name: "index_user_genres_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.citext "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "jti", null: false
    t.string "handle", limit: 20, null: false
    t.string "display_name", limit: 50, null: false
    t.string "avatar_url"
    t.text "bio"
    t.boolean "is_private", default: false, null: false
    t.integer "reading_goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["handle"], name: "index_users_on_handle", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "devices", "users"
  add_foreign_key "follows", "users", column: "followee_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "likes", "users"
  add_foreign_key "mutes", "users", column: "muted_id"
  add_foreign_key "mutes", "users", column: "muter_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "post_hashtags", "hashtags"
  add_foreign_key "post_hashtags", "posts"
  add_foreign_key "posts", "books"
  add_foreign_key "posts", "users"
  add_foreign_key "reposts", "posts"
  add_foreign_key "reposts", "users"
  add_foreign_key "search_histories", "users"
  add_foreign_key "user_favorite_books", "books"
  add_foreign_key "user_favorite_books", "users"
  add_foreign_key "user_genres", "genres"
  add_foreign_key "user_genres", "users"
end
