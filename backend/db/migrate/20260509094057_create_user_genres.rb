class CreateUserGenres < ActiveRecord::Migration[7.2]
  def change
    create_table :user_genres do |t|
      t.references :user, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.datetime :created_at, null: false
    end

    add_index :user_genres, [ :user_id, :genre_id ], unique: true
  end
end
