class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user

  has_many :likes, as: :target, dependent: :destroy

  validates :body, presence: true, length: { maximum: 500 }

  scope :alive, -> { where(deleted_at: nil) }
end
