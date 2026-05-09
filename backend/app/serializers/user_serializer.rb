class UserSerializer
  include JSONAPI::Serializer

  set_type :user

  attributes :handle, :display_name, :avatar_url, :bio, :is_private, :reading_goal,
             :created_at

  attribute :counts do |user|
    {
      posts: user.posts.where(deleted_at: nil).count,
      followers: user.passive_follows.where(status: "accepted").count,
      following: user.active_follows.where(status: "accepted").count
    }
  end
end
