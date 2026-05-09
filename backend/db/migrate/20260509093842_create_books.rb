class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author
      t.string :isbn
      t.string :cover_url
      t.date   :published_on

      t.timestamps
    end

    # ISBN は完全一致検索の主キー的役割
    add_index :books, :isbn, unique: true, where: "isbn IS NOT NULL"
    # タイトル / 著者の部分一致検索を pg_trgm で高速化
    add_index :books, :title,  using: :gin, opclass: :gin_trgm_ops
    add_index :books, :author, using: :gin, opclass: :gin_trgm_ops
  end
end
