# リポスト操作（単純 / 引用）を扱うサービス。
# 要件 RP-01〜RP-09 のビジネスルールを 1 箇所に集約する:
#   - 単純リポストはユーザー × 投稿で 1 件まで（DB 部分 UNIQUE と整合、トグル動作）
#   - 引用リポストは複数作成可（コメント必須）
#   - 非公開アカウントの投稿はリポスト不可（RP-08）
#   - ブロック関係の投稿はリポスト不可（RP-09）
#   - リポスト発生時に元投稿者へ通知（RP-N-01 / RP-N-02）
class RepostService
  class RepostForbidden < StandardError; end
  class CommentRequired < StandardError; end

  # 単純リポスト（トグル）：既存があれば取り消し、無ければ作成
  def self.toggle_simple!(user:, post:)
    raise RepostForbidden if forbidden?(user, post)

    existing = Repost.find_by(user: user, post: post, repost_type: "simple")
    if existing
      existing.destroy!
      return { repost: nil, action: :removed }
    end

    repost = Repost.create!(user: user, post: post, repost_type: "simple")
    create_notification!(repost, post)
    { repost: repost, action: :created }
  end

  # 単純リポスト解除（明示的 DELETE 用、冪等）
  def self.destroy_simple!(user:, post:)
    Repost.where(user: user, post: post, repost_type: "simple").destroy_all
  end

  # 引用リポスト作成（コメント必須）
  def self.create_quote!(user:, post:, comment:)
    raise RepostForbidden if forbidden?(user, post)
    raise CommentRequired if comment.to_s.strip.empty?

    repost = Repost.create!(user: user, post: post, repost_type: "quote", comment: comment)
    create_notification!(repost, post)
    repost
  end

  # 元投稿の単純リポスト件数 + 引用リポスト件数 の合算
  def self.count_for(post)
    Repost.where(post: post).count
  end

  # ---- private ----

  def self.forbidden?(user, post)
    return true if post.user.is_private?           # RP-08
    return true if user.blocked_with?(post.user)   # RP-09

    false
  end
  private_class_method :forbidden?

  def self.create_notification!(repost, post)
    return if post.user_id == repost.user_id # 自己リポストでは通知しない

    Notification.create!(
      recipient: post.user,
      actor: repost.user,
      notification_type: repost.repost_type == "quote" ? "quote_repost" : "repost",
      target: repost
    )
  end
  private_class_method :create_notification!
end
