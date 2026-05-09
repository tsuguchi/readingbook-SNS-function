class Follow < ApplicationRecord
  STATUSES = %w[pending accepted].freeze

  belongs_to :follower, class_name: "User"
  belongs_to :followee, class_name: "User"

  validates :status, inclusion: { in: STATUSES }
  validates :follower_id, uniqueness: { scope: :followee_id }
  validate  :follower_must_differ_from_followee

  scope :pending,  -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  private

  def follower_must_differ_from_followee
    errors.add(:followee_id, :cannot_follow_self) if follower_id.present? && follower_id == followee_id
  end
end
