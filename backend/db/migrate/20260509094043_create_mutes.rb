class CreateMutes < ActiveRecord::Migration[7.2]
  def change
    create_table :mutes do |t|
      t.references :muter, null: false, foreign_key: { to_table: :users }
      t.references :muted, null: false, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false

      t.check_constraint "muter_id <> muted_id", name: "mutes_no_self_mute"
    end

    add_index :mutes, [ :muter_id, :muted_id ], unique: true
  end
end
