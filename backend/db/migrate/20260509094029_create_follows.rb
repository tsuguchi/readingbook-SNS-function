class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      # follower / followee は両方とも users テーブルを参照
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followee, null: false, foreign_key: { to_table: :users }
      # PENDING（リクエスト中） / ACCEPTED（成立済み）
      t.string :status, null: false

      t.timestamps

      # 自分自身をフォローできないようにする CHECK 制約（要件 FL-05）
      t.check_constraint "follower_id <> followee_id", name: "follows_no_self_follow"
    end

    # 重複防止
    add_index :follows, [ :follower_id, :followee_id ], unique: true
    # フォロワー一覧（B のフォロワー = followee_id=B のレコード）
    add_index :follows, [ :followee_id, :status ]
    # フォロイー一覧（A がフォロー中のユーザー）
    add_index :follows, [ :follower_id, :status ]
  end
end
