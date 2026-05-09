FactoryBot.define do
  factory :post do
    user { nil }
    book { nil }
    body { "MyText" }
    deleted_at { "2026-05-09 18:40:02" }
  end
end
