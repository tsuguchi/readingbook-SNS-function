class Post < ApplicationRecord
  belongs_to :user
  belongs_to :book, optional: true

  has_many :comments, dependent: :destroy
  has_many :reposts, dependent: :destroy
  has_many :post_hashtags, dependent: :destroy
  has_many :hashtags, through: :post_hashtags
  has_many :likes, as: :target, dependent: :destroy

  validates :body, presence: true, length: { maximum: 1000 }

  # 論理削除されていない投稿のみ取得するスコープ
  scope :alive, -> { where(deleted_at: nil) }
end
