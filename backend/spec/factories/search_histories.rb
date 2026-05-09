FactoryBot.define do
  factory :search_history do
    user { nil }
    query { "MyString" }
    category { "MyString" }
  end
end
