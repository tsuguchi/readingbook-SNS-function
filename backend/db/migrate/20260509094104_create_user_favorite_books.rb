class CreateUserFavoriteBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :user_favorite_books do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # 同じユーザーが同じ本を 2 回お気に入り登録しない
    add_index :user_favorite_books, [ :user_id, :book_id ], unique: true
    # ユーザーごとの並び順での取得高速化
    add_index :user_favorite_books, [ :user_id, :position ]
  end
end
