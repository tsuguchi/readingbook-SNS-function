FactoryBot.define do
  factory :comment do
    post { nil }
    user { nil }
    body { "MyText" }
    deleted_at { "2026-05-09 18:40:09" }
  end
end
