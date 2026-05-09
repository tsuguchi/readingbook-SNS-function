# タイムライン取得を司るサービス。
# ホーム TL（フォロー中ユーザー）と探索 TL（公開ユーザー全体）の 2 種類を扱う。
# いずれも:
#   - 論理削除済み投稿（deleted_at IS NOT NULL）を除外
#   - ブロック関係のあるユーザーの投稿を除外（要件 BL-03）
#   - ホーム TL のみ:
#     * フォロー中（status='accepted'）ユーザーの投稿に絞る
#     * 自分の投稿も含める（典型的な SNS 仕様）
#     * ミュート対象の投稿を除外（要件 MU-02）
class TimelineService
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  def initialize(user:)
    @user = user
  end

  # ホームタイムライン: 自分 + フォロー中ユーザーの投稿。
  # ミュート対象は除外、ブロック関係は両方向で除外。
  def home(limit: DEFAULT_LIMIT, offset: 0)
    visible_user_ids = following_user_ids + [ @user.id ]
    visible_user_ids -= muted_user_ids
    visible_user_ids -= blocked_user_ids

    Post.alive
        .where(user_id: visible_user_ids)
        .includes(:user, :book, :hashtags)
        .order(created_at: :desc)
        .limit(clamp_limit(limit))
        .offset(offset.to_i)
  end

  # 探索タイムライン: 公開アカウントの新着投稿。
  # ブロック関係はあれば除外、自分の投稿は含めない（探索の定義から）。
  def explore(limit: DEFAULT_LIMIT, offset: 0)
    Post.alive
        .joins(:user)
        .where(users: { is_private: false })
        .where.not(user_id: blocked_user_ids + [ @user.id ])
        .includes(:user, :book, :hashtags)
        .order(created_at: :desc)
        .limit(clamp_limit(limit))
        .offset(offset.to_i)
  end

  private

  def following_user_ids
    Follow.where(follower: @user, status: "accepted").pluck(:followee_id)
  end

  def muted_user_ids
    Mute.where(muter: @user).pluck(:muted_id)
  end

  # 自分→相手 と 相手→自分 の双方向ブロックの合算
  def blocked_user_ids
    a = Block.where(blocker: @user).pluck(:blocked_id)
    b = Block.where(blocked: @user).pluck(:blocker_id)
    (a + b).uniq
  end

  def clamp_limit(value)
    [ value.to_i, MAX_LIMIT ].min.clamp(1, MAX_LIMIT)
  end
end
