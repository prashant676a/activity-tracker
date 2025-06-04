# spec/models/activity_spec.rb
require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it 'belongs to user with discarded scope' do
      association = described_class.reflect_on_association(:user)
      expect(association.scope).to be_present
      # The scope should include with_discarded
    end

    it { should belong_to(:company) }
  end

  describe 'validations' do
    subject { build(:activity) }

    it { should validate_presence_of(:activity_type) }
    it { should validate_inclusion_of(:activity_type).in_array(Activity::ACTIVITY_TYPES) }
  end

  describe 'constants' do
    it 'defines expected activity types' do
      expect(Activity::ACTIVITY_TYPES).to match_array(%w[
        login
        logout
        give_recognition
        receive_recognition
        profile_update
        admin_action
      ])
    end
  end

  describe 'database constraints' do
    it 'has a check constraint for valid activity types' do
      activity = build(:activity)
      # Try to bypass Rails validation
      activity.activity_type = 'invalid_type'

      expect {
        activity.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /valid_activity_type/)
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      context '#set_occurred_at' do
        it 'sets occurred_at if not provided on create' do
          activity = build(:activity, occurred_at: nil)
          activity.valid?
          expect(activity.occurred_at).to be_within(1.second).of(Time.current)
        end

        it 'does not change occurred_at on update' do
          activity = create(:activity, occurred_at: 2.hours.ago)
          original_time = activity.occurred_at
          activity.metadata = { updated: true }
          activity.save!
          expect(activity.occurred_at).to eq(original_time)
        end
      end

      context '#sanitize_metadata' do
        it 'removes sensitive keys from metadata' do
          activity = build(:activity, :with_sensitive_data)
          activity.valid?

          %w[password token secret api_key credit_card ssn].each do |key|
            expect(activity.metadata).not_to have_key(key)
          end
          expect(activity.metadata['safe_data']).to eq('should_remain')
        end

        it 'handles nil metadata' do
          activity = build(:activity, metadata: nil)
          expect { activity.valid? }.not_to raise_error
        end

        it 'converts keys to strings' do
          activity = build(:activity, metadata: { symbol_key: 'value' })
          activity.valid?
          expect(activity.metadata).to have_key('symbol_key')
          expect(activity.metadata).not_to have_key(:symbol_key)
        end
      end
    end
  end

  describe 'custom validations' do
    describe '#user_belongs_to_company' do
      let(:company1) { create(:company) }
      let(:company2) { create(:company) }
      let(:user) { create(:user, company: company1) }

      it 'is valid when user belongs to the same company' do
        activity = build(:activity, user: user, company: company1)
        expect(activity).to be_valid
      end

      it 'is invalid when user belongs to different company' do
        activity = build(:activity, user: user, company: company2)
        expect(activity).not_to be_valid
        expect(activity.errors[:user]).to include('must belong to the same company')
      end
    end
  end

  describe 'scopes' do
    let(:company) { create(:company) }
    let(:user) { create(:user, company: company) }
    let!(:recent_activity) { create(:activity, user: user, occurred_at: 1.hour.ago) }
    let!(:old_activity) { create(:activity, user: user, occurred_at: 1.week.ago) }
    let!(:login_activity) { create(:activity, :login, user: user, occurred_at: 30.minutes.ago) }

    describe '.recent' do
      it 'orders by occurred_at descending' do
        activities = Activity.recent
        expect(activities.first).to eq(login_activity)
        expect(activities.last).to eq(old_activity)
      end
    end

    describe '.for_company' do
      let(:other_company) { create(:company) }
      let(:other_user) { create(:user, company: other_company) }
      let!(:other_activity) { create(:activity, user: other_user) }

      it 'returns activities for specified company only' do
        results = Activity.for_company(company.id)
        expect(results).to include(recent_activity, old_activity, login_activity)
        expect(results).not_to include(other_activity)
      end
    end

    describe '.between' do
      it 'filters by date range' do
        results = Activity.between(2.hours.ago, Time.current)
        expect(results).to include(recent_activity, login_activity)
        expect(results).not_to include(old_activity)
      end

      it 'handles string dates' do
        results = Activity.between(2.hours.ago.to_s, Time.current.to_s)
        expect(results).to include(recent_activity, login_activity)
      end

      it 'includes full day when using date strings' do
        today = Date.current
        yesterday = today - 1.day

        create(:activity, user: user, occurred_at: yesterday.beginning_of_day + 1.minute)
        create(:activity, user: user, occurred_at: yesterday.end_of_day - 1.minute)

        results = Activity.between(yesterday.to_s, yesterday.to_s)
        expect(results.count).to eq(2)
      end
    end
  end

  describe '.filter_by_params' do
    let(:company) { create(:company) }
    let(:user1) { create(:user, company: company) }
    let(:user2) { create(:user, company: company) }

    before do
      create(:activity, :login, user: user1, occurred_at: 1.hour.ago)
      create(:activity, :logout, user: user1, occurred_at: 30.minutes.ago)
      create(:activity, :login, user: user2, occurred_at: 2.hours.ago)
    end

    it 'filters by multiple parameters' do
      params = {
        user_id: user1.id,
        activity_type: 'login'
      }

      results = Activity.filter_by_params(params)
      expect(results.count).to eq(1)
      expect(results.first.user).to eq(user1)
      expect(results.first.activity_type).to eq('login')
    end

    it 'returns recent scope when no params provided' do
      results = Activity.filter_by_params({})
      expect(results.to_sql).to include('ORDER BY')
    end
  end

  describe 'handling discarded users' do
    let(:user) { create(:user) }
    let(:activity) { create(:activity, user: user) }

    it 'maintains association with discarded users' do
      user.discard
      activity.reload

      expect(activity.user).to eq(user)
      expect(activity.user.discarded?).to be true
    end

    it 'includes discarded users when loading activities' do
      activity
      user.discard

      # This should not raise an error
      loaded_activity = Activity.includes(:user).find(activity.id)
      expect(loaded_activity.user).to be_present
    end
  end

  describe 'metadata handling' do
    it 'preserves JSONB data types' do
      metadata = {
        'string' => 'value',
        'integer' => 123,
        'float' => 123.45,
        'boolean' => true,
        'array' => [ 1, 2, 3 ],
        'nested' => { 'key' => 'value' }
      }

      activity = create(:activity, metadata: metadata)
      activity.reload

      expect(activity.metadata['string']).to eq('value')
      expect(activity.metadata['integer']).to eq(123)
      expect(activity.metadata['float']).to eq(123.45)
      expect(activity.metadata['boolean']).to eq(true)
      expect(activity.metadata['array']).to eq([ 1, 2, 3 ])
      expect(activity.metadata['nested']['key']).to eq('value')
    end
  end
end
