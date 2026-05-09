FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123" }
    sequence(:handle) { |n| "user#{n}" }
    sequence(:display_name) { |n| "User #{n}" }
    is_private { false }
  end
end
