class PostHashtag < ApplicationRecord
  belongs_to :post
  belongs_to :hashtag

  validates :post_id, uniqueness: { scope: :hashtag_id }
end
