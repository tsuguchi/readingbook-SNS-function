class Like < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  TARGET_TYPES = %w[Post Book Comment].freeze

  validates :target_type, inclusion: { in: TARGET_TYPES }
  validates :user_id, uniqueness: { scope: %i[target_type target_id] }
end
