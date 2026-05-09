FactoryBot.define do
  factory :follow do
    follower { nil }
    followee { nil }
    status { "MyString" }
  end
end
