class Genre < ApplicationRecord
  has_many :user_genres, dependent: :destroy
  has_many :users, through: :user_genres

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
end
