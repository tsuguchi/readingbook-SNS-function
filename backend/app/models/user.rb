class User < ApplicationRecord
  # devise-jwt の JTI Matcher 戦略：
  # users.jti カラムと JWT ペイロードの jti を突合して失効を判定する。
  # ログアウト時に jti を新しい UUID に置き換えれば、過去の JWT はすべて無効化される。
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # ---- 投稿・コメント・本棚関連 ----
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :user_genres, dependent: :destroy
  has_many :genres, through: :user_genres
  has_many :user_favorite_books, -> { order(:position) }, dependent: :destroy
  has_many :favorite_books, through: :user_favorite_books, source: :book

  # ---- いいね（ポリモーフィック） ----
  has_many :likes, dependent: :destroy

  # ---- リポスト ----
  has_many :reposts, dependent: :destroy

  # ---- フォロー（自己参照、双方向） ----
  has_many :active_follows,  class_name: "Follow", foreign_key: :follower_id, dependent: :destroy, inverse_of: :follower
  has_many :passive_follows, class_name: "Follow", foreign_key: :followee_id, dependent: :destroy, inverse_of: :followee
  has_many :followees, through: :active_follows,  source: :followee
  has_many :followers, through: :passive_follows, source: :follower

  # ---- ブロック / ミュート ----
  has_many :active_blocks,  class_name: "Block", foreign_key: :blocker_id, dependent: :destroy, inverse_of: :blocker
  has_many :passive_blocks, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy, inverse_of: :blocked
  has_many :blocking, through: :active_blocks,  source: :blocked
  has_many :blockers, through: :passive_blocks, source: :blocker

  has_many :active_mutes, class_name: "Mute", foreign_key: :muter_id, dependent: :destroy, inverse_of: :muter
  has_many :muting, through: :active_mutes, source: :muted

  # ---- 通知（受け手 / 行為者） ----
  has_many :received_notifications, class_name: "Notification", foreign_key: :recipient_id,
                                    dependent: :destroy, inverse_of: :recipient
  has_many :sent_notifications,     class_name: "Notification", foreign_key: :actor_id,
                                    dependent: :destroy, inverse_of: :actor

  # ---- その他 ----
  has_many :search_histories, dependent: :destroy
  has_many :devices, dependent: :destroy

  # ---- バリデーション ----
  validates :handle, presence: true, uniqueness: { case_sensitive: false },
                     length: { in: 3..20 },
                     format: { with: /\A[A-Za-z0-9_]+\z/, message: :invalid_handle }
  validates :display_name, presence: true, length: { maximum: 50 }
  validates :bio, length: { maximum: 200 }, allow_blank: true
  validates :reading_goal, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # ---- ブロック関係判定 ----
  # self <-> other のいずれか方向でブロック関係が成立しているか。
  # 要件 BL-03 / LK-08 / RP-09 でいいね・リポスト・フォローの拒否判定に使う。
  def blocked_with?(other)
    return false if other.nil? || self == other

    Block.where(
      "(blocker_id = :a AND blocked_id = :b) OR (blocker_id = :b AND blocked_id = :a)",
      a: id, b: other.id
    ).exists?
  end
end
