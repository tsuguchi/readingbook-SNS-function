class Repost < ApplicationRecord
  # `type` は STI のため repost_type を使用、Rails の inheritance_column を無効化
  self.inheritance_column = nil

  belongs_to :user
  belongs_to :post

  REPOST_TYPES = %w[simple quote].freeze

  validates :repost_type, inclusion: { in: REPOST_TYPES }
  validates :comment, length: { maximum: 500 }, allow_blank: true
  validates :comment, presence: true, if: -> { repost_type == "quote" }

  # 単純リポストはユーザー × 投稿で 1 件まで（DB の部分 UNIQUE と整合）
  validates :user_id, uniqueness: { scope: :post_id }, if: -> { repost_type == "simple" }
end
