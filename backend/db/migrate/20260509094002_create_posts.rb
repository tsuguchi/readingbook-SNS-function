class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      # book は任意（読書記録ではなく一般的な感想投稿もありうる）
      t.references :book, null: true, foreign_key: true
      t.text :body, null: false
      # 全文検索用の tsvector 列（pg_search でも使うが、ここで列を確保しておく）
      t.tsvector :body_tsv
      t.datetime :deleted_at

      t.timestamps
    end

    # タイムライン取得（生存投稿の新着順）の主インデックス
    add_index :posts, [ :created_at, :id ], where: "deleted_at IS NULL", order: { created_at: :desc, id: :desc },
                                          name: "index_posts_on_alive_timeline"
    # ユーザー別投稿一覧
    add_index :posts, [ :user_id, :created_at ], where: "deleted_at IS NULL",
                                               name: "index_posts_on_user_alive_timeline"
    # 全文検索用 GIN
    add_index :posts, :body_tsv, using: :gin
  end
end
