class Hashtag < ApplicationRecord
  has_many :post_hashtags, dependent: :destroy
  has_many :posts, through: :post_hashtags

  validates :name, presence: true, uniqueness: true,
                   length: { maximum: 100 },
                   format: { without: /\s/, message: :must_not_contain_whitespace }
end
