FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    activity_tracking_enabled { true }
    activity_tracking_config { {} }

    trait :with_tracking_disabled do
      activity_tracking_enabled { false }
    end

    trait :with_limited_tracking do
      activity_tracking_config do
        {
          enabled_activity_types: [ 'login', 'logout' ],
          retention_days: 365
        }
      end
    end

    trait :with_users do
      transient do
        users_count { 5 }
      end

      after(:create) do |company, evaluator|
        create_list(:user, evaluator.users_count, company: company)
      end
    end
  end
end
