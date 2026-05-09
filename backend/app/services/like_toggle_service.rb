# いいねの作成・削除を冪等に行い、副作用（ブロック関係チェック・通知発火）を
# 一括で扱うサービス。コントローラはこのサービスを呼ぶだけで以下を保証できる。
#
# - 同一ユーザー × 同一対象は最大 1 件（要件 LK-03）：DB UNIQUE 制約 + find_or_create_by
# - 既にいいね済みでも 2 回目の create で例外を投げない（API 冪等性）
# - 未いいね状態でも DELETE が例外にならない
# - ブロック関係（双方向）の場合は LikeForbidden を raise（コントローラで 404 化）
# - いいね作成時に通知を作成（要件 LK-N-01）。Book は通知対象外（LK-N-05）、
#   自己いいねも通知対象外（LK-N-04）。
class LikeToggleService
  class LikeForbidden < StandardError; end

  def initialize(user:, target:)
    @user = user
    @target = target
  end

  # いいねを作成（既に存在すれば既存レコードを返す）
  def like!
    raise LikeForbidden if blocked?

    like = nil
    ActiveRecord::Base.transaction do
      like = Like.find_or_create_by!(user: @user, target_type: target_type, target_id: @target.id)
      create_notification!(like) if like.previously_new_record?
    end
    like
  end

  # いいねを削除（存在しなければ何もしない、いずれの場合も冪等）
  def unlike!
    Like.where(user: @user, target_type: target_type, target_id: @target.id).destroy_all
  end

  # 件数取得（カウンタキャッシュ未導入のため都度集計）
  def likes_count
    Like.where(target_type: target_type, target_id: @target.id).count
  end

  private

  # ポリモーフィック型名（"Post" / "Comment" / "Book"）
  def target_type
    @target.class.name
  end

  # Book は所有者を持たないためブロック判定不要（LK-08 は対人関係のみ）
  def blocked?
    target_owner = owner_of(@target)
    return false if target_owner.nil?

    @user.blocked_with?(target_owner)
  end

  # Post / Comment は user 関連あり、Book は無し
  def owner_of(target)
    return target.user if target.respond_to?(:user)

    nil
  end

  def create_notification!(like)
    target_owner = owner_of(@target)
    return if target_owner.nil?       # Book いいねは通知対象外（LK-N-05）
    return if target_owner == @user   # 自己いいねは通知対象外（LK-N-04）

    Notification.create!(
      recipient: target_owner,
      actor: @user,
      notification_type: notification_type_for_target,
      target: like
    )
  end

  def notification_type_for_target
    case @target
    when Post    then "like_post"
    when Comment then "like_comment"
    end
  end
end
