class Device < ApplicationRecord
  PLATFORMS = %w[ios android web].freeze

  belongs_to :user

  validates :platform, inclusion: { in: PLATFORMS }
  validates :token, presence: true, uniqueness: { scope: :platform }
end
