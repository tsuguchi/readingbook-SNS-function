# フォロー / アンフォロー / リクエスト承認・拒否を扱うサービス。
# 公開アカウント = 即時フォロー成立、非公開アカウント = リクエスト保留 のハイブリッド
# モデル（要件 FL-01 / FL-02）を一箇所に集約する。
class FollowService
  class FollowForbidden < StandardError; end
  class CannotFollowSelf < StandardError; end

  def self.follow!(follower:, followee:)
    raise CannotFollowSelf if follower == followee
    raise FollowForbidden if follower.blocked_with?(followee)

    status = followee.is_private? ? "pending" : "accepted"

    follow = Follow.find_or_create_by!(follower: follower, followee: followee) do |f|
      f.status = status
    end

    if follow.previously_new_record?
      create_notification!(follow, status)
    end

    follow
  end

  def self.unfollow!(follower:, followee:)
    Follow.where(follower: follower, followee: followee).destroy_all
  end

  # フォローリクエスト承認（要件 FL-N-03）
  def self.accept!(follow)
    return follow unless follow.status == "pending"

    follow.update!(status: "accepted")
    Notification.create!(
      recipient: follow.follower,
      actor: follow.followee,
      notification_type: "follow_accepted",
      target: follow
    )
    follow
  end

  # フォローリクエスト拒否（拒否は通知しない＝要件推奨）
  def self.reject!(follow)
    follow.destroy!
  end

  # 公開アカウントへのフォローは follow 通知、非公開へは follow_request 通知
  def self.create_notification!(follow, status)
    notification_type =
      case status
      when "accepted" then "follow"
      when "pending"  then "follow_request"
      end
    Notification.create!(
      recipient: follow.followee,
      actor: follow.follower,
      notification_type: notification_type,
      target: follow
    )
  end
  private_class_method :create_notification!
end
