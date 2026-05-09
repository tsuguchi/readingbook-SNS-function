class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # 投稿に紐づくコメント一覧の取得高速化
    add_index :comments, [ :post_id, :created_at ], where: "deleted_at IS NULL",
                                                  name: "index_comments_on_post_alive"
  end
end
