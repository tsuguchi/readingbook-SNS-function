class CreateDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      # ios / android / web
      t.string :platform, null: false
      # FCM デバイストークン or Web Push エンドポイント
      t.string :token, null: false

      t.timestamps
    end

    # platform × token の組合せでユニーク（端末を一意に識別）
    add_index :devices, [ :platform, :token ], unique: true
  end
end
