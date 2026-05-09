class RepostSerializer
  include JSONAPI::Serializer

  set_type :repost

  attributes :repost_type, :comment, :created_at

  attribute :user do |repost|
    UserSerializer.new(repost.user).serializable_hash[:data]
  end

  attribute :post do |repost, params|
    PostSerializer.new(repost.post, params: params).serializable_hash[:data]
  end
end
