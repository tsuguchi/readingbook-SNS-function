class CreateSearchHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :search_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :query, null: false
      # all / users / books / posts / tags
      t.string :category, null: false, default: "all"
      t.datetime :executed_at, null: false

      t.datetime :created_at, null: false
    end

    # 自分の検索履歴を新しい順で取得する用
    add_index :search_histories, [ :user_id, :executed_at ],
              order: { executed_at: :desc },
              name: "index_search_histories_on_user_recent"
  end
end
