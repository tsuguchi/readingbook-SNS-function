class CreatePostHashtags < ActiveRecord::Migration[7.2]
  def change
    create_table :post_hashtags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :hashtag, null: false, foreign_key: true

      t.datetime :created_at, null: false
    end

    # 同一投稿に同一タグを複数付けない
    add_index :post_hashtags, [ :post_id, :hashtag_id ], unique: true
    # タグ別の投稿一覧取得高速化
    add_index :post_hashtags, [ :hashtag_id, :post_id ]
  end
end
