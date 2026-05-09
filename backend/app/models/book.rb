class Book < ApplicationRecord
  has_many :posts, dependent: :nullify
  has_many :user_favorite_books, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  has_many :likes, as: :target, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :isbn, uniqueness: true, allow_nil: true,
                   format: { with: /\A\d{10}(\d{3})?\z/, message: :invalid_isbn }, allow_blank: true
end
