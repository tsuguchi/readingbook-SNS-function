class CommentSerializer
  include JSONAPI::Serializer

  set_type :comment

  attributes :body, :created_at

  attribute :post_id do |comment|
    comment.post_id.to_s
  end

  attribute :user do |comment|
    UserSerializer.new(comment.user).serializable_hash[:data]
  end

  attribute :counts do |comment|
    { likes: comment.likes.count }
  end

  attribute :is_liked do |comment, params|
    next false if params[:current_user].nil?

    comment.likes.exists?(user_id: params[:current_user].id)
  end
end
