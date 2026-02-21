FactoryBot.define do
  factory :session do
    association :user
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
  end
end
