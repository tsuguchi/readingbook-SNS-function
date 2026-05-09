class HashtagSerializer
  include JSONAPI::Serializer

  set_type :hashtag

  attributes :name

  attribute :counts do |hashtag|
    { posts: hashtag.posts.where(deleted_at: nil).count }
  end
end
