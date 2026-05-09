# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.citext :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Devise JWT (Denylist 戦略用)
      t.string :jti, null: false

      ## アプリ独自プロフィール項目（要件定義 / ER図 参照）
      t.string  :handle,        null: false, limit: 20
      t.string  :display_name,  null: false, limit: 50
      t.string  :avatar_url
      t.text    :bio
      t.boolean :is_private,    null: false, default: false
      t.integer :reading_goal

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :handle,               unique: true
    add_index :users, :jti,                  unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
