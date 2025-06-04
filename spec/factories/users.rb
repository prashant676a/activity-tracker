# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    company
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end

    trait :company_admin do
      role { 'company_admin' }
    end

    trait :discarded do
      discarded_at { 1.day.ago }
    end

    trait :with_activities do
      transient do
        activities_count { 10 }
      end

      after(:create) do |user, evaluator|
        create_list(:activity, evaluator.activities_count, user: user, company: user.company)
      end
    end
  end
end
