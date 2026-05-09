class PostSerializer
  include JSONAPI::Serializer

  set_type :post

  attributes :body, :created_at, :updated_at

  attribute :user do |post|
    UserSerializer.new(post.user).serializable_hash[:data]
  end

  attribute :book do |post|
    next nil unless post.book

    BookSerializer.new(post.book).serializable_hash[:data]
  end

  attribute :hashtags do |post|
    post.hashtags.pluck(:name)
  end

  attribute :counts do |post|
    {
      likes: post.likes.count,
      comments: post.comments.where(deleted_at: nil).count,
      reposts: post.reposts.count
    }
  end

  attribute :is_liked do |post, params|
    next false if params[:current_user].nil?

    post.likes.exists?(user_id: params[:current_user].id)
  end

  attribute :is_reposted do |post, params|
    next false if params[:current_user].nil?

    post.reposts.exists?(user_id: params[:current_user].id, repost_type: "simple")
  end
end
