# spec/services/activity_tracker_spec.rb
require 'rails_helper'

RSpec.describe ActivityTrackerService do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  describe '.track' do
    context 'with valid parameters' do
      it 'creates an activity successfully' do
        result = described_class.track(
          user: user,
          activity_type: 'login',
          metadata: { source: 'web' }
        )

        expect(result[:success]).to be true
        expect(result[:message]).to eq('Activity tracked')
        expect(Activity.last.activity_type).to eq('login')
        expect(Activity.last.metadata['source']).to eq('web')
      end

      it 'enriches metadata with request information' do
        request = double(
          remote_ip: '192.168.1.100',
          user_agent: 'Mozilla/5.0',
          request_id: 'abc123'
        )

        described_class.track(
          user: user,
          activity_type: 'login',
          request: request
        )

        activity = Activity.last
        expect(activity.metadata['ip_address']).to eq('192.168.1.0') # anonymized
        expect(activity.metadata['user_agent']).to eq('Mozilla/5.0')
        expect(activity.metadata['request_id']).to eq('abc123')
      end

      it 'respects company tracking settings' do
        company.update(
          activity_tracking_config: {
            enabled_activity_types: [ 'login' ]
          }
        )

        # Should track login
        result = described_class.track(
          user: user,
          activity_type: 'login'
        )
        expect(result[:success]).to be true

        # Should not track logout
        result = described_class.track(
          user: user,
          activity_type: 'logout'
        )
        expect(result[:success]).to be false
        expect(result[:message]).to eq('Tracking disabled')
      end
    end

    context 'with invalid parameters' do
      it 'fails without user' do
        result = described_class.track(
          user: nil,
          activity_type: 'login'
        )

        expect(result[:success]).to be false
        expect(result[:message]).to eq('User required')
      end

      it 'fails with invalid activity type' do
        result = described_class.track(
          user: user,
          activity_type: 'invalid_type'
        )

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Invalid activity type')
      end
    end

    context 'when tracking is disabled' do
      before do
        company.update(activity_tracking_enabled: false)
      end

      it 'does not create activity' do
        expect {
          described_class.track(
            user: user,
            activity_type: 'login'
          )
        }.not_to change(Activity, :count)
      end
    end

    context 'error handling' do
      it 'handles database errors gracefully' do
        allow(Activity).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        result = described_class.track(
          user: user,
          activity_type: 'login'
        )

        expect(result[:success]).to be false
        expect(Activity.count).to eq(0)
      end

      it 'logs errors' do
        allow(Activity).to receive(:create!).and_raise(StandardError, "Test error")

        # Expect to receive error with a JSON string
        expect(Rails.logger).to receive(:error) do |json_string|
          # Verify it's valid JSON
          expect { JSON.parse(json_string) }.not_to raise_error

          # Parse and check contents
          error_data = JSON.parse(json_string)
          expect(error_data['error']).to eq("Activity tracking failed")
          expect(error_data['user_id']).to eq(user.id)
          expect(error_data['company_id']).to eq(user.company_id)
          expect(error_data['activity_type']).to eq('login')
          expect(error_data['error_class']).to eq('StandardError')
          expect(error_data['error_message']).to eq('Test error')
        end

        described_class.track(
          user: user,
          activity_type: 'login'
        )
      end
    end
  end

  describe '.track!' do
    it 'raises error on failure' do
      expect {
        described_class.track!(
          user: nil,
          activity_type: 'login'
        )
      }.to raise_error(ActivityTrackerService::TrackingError, 'User required')
    end

    it 'returns result on success' do
      result = described_class.track!(
        user: user,
        activity_type: 'login'
      )

      expect(result[:success]).to be true
    end
  end

  describe '.bulk_track' do
    let(:user2) { create(:user, company: company) }

    it 'tracks multiple activities' do
      activities_data = [
        { user_id: user.id, activity_type: 'login', metadata: { bulk: true } },
        { user_id: user2.id, activity_type: 'logout', metadata: { bulk: true } }
      ]

      result = described_class.bulk_track(activities_data)

      expect(result[:total]).to eq(2)
      expect(result[:succeeded]).to eq(2)
      expect(result[:failed]).to eq(0)
      expect(Activity.count).to eq(2)
    end

    it 'handles partial failures' do
      # Need another valid user for testing
      user2 = create(:user, company: company)

      activities_data = [
        { user_id: user2.id, activity_type: 'login', metadata: {} },              # ✓ should succeed
        { user_id: 999999, activity_type: 'logout' },             # ✗ non-existent user
        { user_id: user2.id, activity_type: 'invalid_type' }      # ✗ invalid type
      ]

      result = described_class.bulk_track(activities_data)

      expect(result[:total]).to eq(3)
      expect(result[:succeeded]).to eq(1)  # Only login succeeds
      expect(result[:failed]).to eq(2)     # Other two fail

      # Check the results array for specific failures
      expect(result[:results][0][:success]).to be true
      expect(result[:results][1][:success]).to be false
      expect(result[:results][1][:error]).to eq("User not found")
      expect(result[:results][2][:success]).to be false
      expect(result[:results][2][:message]).to eq("Invalid activity type")
    end
  end

  describe 'async processing' do
    it 'queues job when threshold is met' do
      # Create 1000 activities in the last hour to trigger async
      allow_any_instance_of(ActiveRecord::Relation).to receive(:count).and_return(1001)

      expect(ActivityTrackingJob).to receive(:perform_later)

      result = described_class.track(
        user: user,
        activity_type: 'login'
      )

      expect(result[:message]).to eq('Activity queued')
    end
  end
end
