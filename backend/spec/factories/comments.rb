FactoryBot.define do
  factory :comment do
    post
    user
    body { "Sample comment body" }
    deleted_at { nil }
  end
end
