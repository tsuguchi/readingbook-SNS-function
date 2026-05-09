class UserFavoriteBook < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :user_id, uniqueness: { scope: :book_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
