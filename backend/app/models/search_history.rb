class SearchHistory < ApplicationRecord
  CATEGORIES = %w[all users books posts tags].freeze

  belongs_to :user

  validates :query, presence: true, length: { maximum: 255 }
  validates :category, inclusion: { in: CATEGORIES }

  before_validation :set_executed_at, on: :create

  private

  def set_executed_at
    self.executed_at ||= Time.current
  end
end
