class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor,     null: false, foreign_key: { to_table: :users }
      # `type` は STI 予約語のため notification_type を使う
      t.string :notification_type, null: false
      # 対象リソース（投稿・コメント・ユーザーなど）
      t.references :target, polymorphic: true, null: true
      t.datetime :read_at

      t.datetime :created_at, null: false
    end

    # 通知一覧の新着順取得
    add_index :notifications, [ :recipient_id, :created_at ],
              order: { created_at: :desc },
              name: "index_notifications_on_recipient_timeline"
    # 未読件数取得（部分インデックスで未読のみ）
    add_index :notifications, :recipient_id,
              where: "read_at IS NULL",
              name: "index_notifications_unread"
  end
end
