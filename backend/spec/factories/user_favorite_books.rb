FactoryBot.define do
  factory :user_favorite_book do
    user { nil }
    book { nil }
    position { 1 }
  end
end
