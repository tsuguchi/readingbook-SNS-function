class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate  :blocker_must_differ_from_blocked

  private

  def blocker_must_differ_from_blocked
    errors.add(:blocked_id, :cannot_block_self) if blocker_id.present? && blocker_id == blocked_id
  end
end
