# 通知レコードを API レスポンスにシリアライズする。
#
# notification_type ごとに target の表示を切り替える:
#   - like_post / like_comment       … 紐づく Post / Comment を返す（Like レコードは中間扱い）
#   - follow / follow_request /
#     follow_accepted                … target は null（actor の User で十分）
#   - repost / quote_repost          … 紐づく Post を返す（リポスト元）
#   - comment                        … Comment（とその親 Post 情報）を返す
class NotificationSerializer
  include JSONAPI::Serializer

  set_type :notification

  attributes :notification_type, :read_at, :created_at

  attribute :actor do |notification|
    UserSerializer.new(notification.actor).serializable_hash[:data]
  end

  attribute :target do |notification, params|
    NotificationSerializer.target_payload(notification, params)
  end

  def self.target_payload(notification, params)
    case notification.notification_type
    when "like_post", "like_comment"
      serialize_like_target(notification.target, params)
    when "repost", "quote_repost"
      return nil unless notification.target.is_a?(Repost)

      RepostSerializer.new(notification.target, params: params).serializable_hash[:data]
    when "comment"
      return nil unless notification.target.is_a?(Comment)

      CommentSerializer.new(notification.target, params: params).serializable_hash[:data]
    end
  end

  def self.serialize_like_target(like, params)
    return nil unless like.respond_to?(:target)

    case like.target
    when Post    then PostSerializer.new(like.target, params: params).serializable_hash[:data]
    when Comment then CommentSerializer.new(like.target, params: params).serializable_hash[:data]
    end
  end
end
