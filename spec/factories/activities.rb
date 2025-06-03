# spec/factories/activities.rb
FactoryBot.define do
  factory :activity do
    association :user
    company { user.company }
    activity_type { 'login' }
    occurred_at { Time.current }
    metadata { {} }
    
    # Ensure user and company match
    before(:create) do |activity|
      if activity.user && !activity.company
        activity.company = activity.user.company
      end
    end
    
    Activity::ACTIVITY_TYPES.each do |type|
      trait type.to_sym do
        activity_type { type }
      end
    end
    
    trait :with_metadata do
      metadata do
        {
          ip_address: Faker::Internet.ip_v4_address,
          user_agent: Faker::Internet.user_agent,
          session_id: SecureRandom.uuid
        }
      end
    end
    
    trait :recent do
      occurred_at { rand(1..24).hours.ago }
    end
    
    trait :old do
      occurred_at { rand(1..12).months.ago }
    end
    
    trait :with_sensitive_data do
      metadata do
        {
          password: 'should_be_removed',
          api_key: 'should_be_removed',
          token: 'should_be_removed',
          safe_data: 'should_remain'
        }
      end
    end
  end
end