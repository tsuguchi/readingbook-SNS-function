class Mute < ApplicationRecord
  belongs_to :muter, class_name: "User"
  belongs_to :muted, class_name: "User"

  validates :muter_id, uniqueness: { scope: :muted_id }
  validate  :muter_must_differ_from_muted

  private

  def muter_must_differ_from_muted
    errors.add(:muted_id, :cannot_mute_self) if muter_id.present? && muter_id == muted_id
  end
end
