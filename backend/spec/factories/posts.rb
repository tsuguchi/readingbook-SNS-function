FactoryBot.define do
  factory :post do
    user
    body { "Sample post body" }
    book { nil }
    deleted_at { nil }
  end
end
