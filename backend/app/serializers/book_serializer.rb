class BookSerializer
  include JSONAPI::Serializer

  set_type :book

  attributes :title, :author, :isbn, :cover_url, :published_on
end
