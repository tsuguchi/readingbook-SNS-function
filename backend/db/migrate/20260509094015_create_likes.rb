class CreateLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target, polymorphic: true, null: false

      t.datetime :created_at, null: false
    end

    # 同一ユーザー × 同一対象は最大 1 件（要件 LK-03）
    add_index :likes, [ :user_id, :target_type, :target_id ], unique: true,
                                                            name: "index_likes_unique_user_target"
  end
end
