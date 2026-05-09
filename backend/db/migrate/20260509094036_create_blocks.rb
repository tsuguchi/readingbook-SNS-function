class CreateBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked, null: false, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false

      t.check_constraint "blocker_id <> blocked_id", name: "blocks_no_self_block"
    end

    # blocker_id / blocked_id 単独のインデックスは t.references で自動生成済み。
    # ここでは複合 UNIQUE のみ追加。
    add_index :blocks, [ :blocker_id, :blocked_id ], unique: true
  end
end
