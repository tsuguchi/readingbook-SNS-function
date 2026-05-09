class BookSerializer
  include JSONAPI::Serializer

  set_type :book

  attributes :title, :author, :isbn, :cover_url, :published_on

  attribute :counts do |book|
    {
      likes: book.likes.count,
      posts: book.posts.where(deleted_at: nil).count
    }
  end

  attribute :is_liked do |book, params|
    next false if params[:current_user].nil?

    book.likes.exists?(user_id: params[:current_user].id)
  end
end
