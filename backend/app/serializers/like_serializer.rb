class LikeSerializer
  include JSONAPI::Serializer

  set_type :like

  attributes :target_type, :created_at

  attribute :target do |like, params|
    target = like.target
    case target
    when Post
      PostSerializer.new(target, params: params).serializable_hash[:data]
    when Comment
      CommentSerializer.new(target, params: params).serializable_hash[:data]
    when Book
      BookSerializer.new(target).serializable_hash[:data]
    end
  end
end
