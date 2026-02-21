FactoryBot.define do
  factory :invitation do
    association :created_by, factory: :user
    expires_at { 24.hours.from_now }

    trait :used do
      association :used_by, factory: :user
      used_at { Time.current }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
