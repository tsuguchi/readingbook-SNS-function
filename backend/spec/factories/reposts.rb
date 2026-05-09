FactoryBot.define do
  factory :repost do
    user { nil }
    post { nil }
    type { "" }
    comment { "MyText" }
  end
end
