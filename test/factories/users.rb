FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { "user" }
    banned { false }

    trait :admin do
      role { "admin" }
    end

    trait :banned do
      banned { true }
      banned_at { Time.current }
    end

    trait :with_otp do
      otp_secret { ROTP::Base32.random }
      otp_required { true }
    end
  end
end
