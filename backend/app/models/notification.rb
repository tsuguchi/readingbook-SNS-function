class Notification < ApplicationRecord
  # `type` は STI のため notification_type を使用
  self.inheritance_column = nil

  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User"
  belongs_to :target, polymorphic: true, optional: true

  NOTIFICATION_TYPES = %w[
    like_post
    like_comment
    follow
    follow_request
    follow_accepted
    repost
    quote_repost
    comment
  ].freeze

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  scope :unread, -> { where(read_at: nil) }
  scope :for, ->(user) { where(recipient: user).order(created_at: :desc) }

  def read!
    update!(read_at: Time.current) if read_at.nil?
  end
end
