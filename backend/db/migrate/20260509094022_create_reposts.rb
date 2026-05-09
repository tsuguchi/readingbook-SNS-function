class CreateReposts < ActiveRecord::Migration[7.2]
  def change
    create_table :reposts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      # `type` は Rails STI 予約語のため repost_type を採用
      t.string :repost_type, null: false
      t.text   :comment

      t.datetime :created_at, null: false
    end

    # 単純リポストはユーザー × 投稿で 1 件まで（トグル動作のため）
    # 引用リポストは複数投稿可なので部分 UNIQUE 制約とする
    add_index :reposts, [ :user_id, :post_id ], unique: true,
                                              where: "repost_type = 'simple'",
                                              name: "index_reposts_unique_simple"

    # 元投稿に紐づくリポスト一覧の取得高速化
    add_index :reposts, [ :post_id, :created_at ]
  end
end
