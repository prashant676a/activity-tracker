# spec/jobs/activity_tracking_job_spec.rb
require 'rails_helper'

RSpec.describe ActivityTrackingJob, type: :job do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  describe '#perform' do
    let(:activity_data) do
      {
        user_id: user.id,
        activity_type: 'login',
        metadata: { source: 'job' },
        occurred_at: Time.current
      }
    end

    it 'creates an activity with correct tenant' do
      expect {
        described_class.perform_now(activity_data)
      }.to change(Activity, :count).by(1)

      activity = Activity.last
      expect(activity.user).to eq(user)
      expect(activity.company).to eq(company)
      expect(activity.activity_type).to eq('login')
      expect(activity.metadata['source']).to eq('job')
    end

    it 'sets the correct tenant context' do
      # Create another company to ensure tenant isolation
      other_company = create(:company)
      
      described_class.perform_now(activity_data)
      
      # Verify activity was created for correct company
      expect(Activity.last.company).to eq(company)
      expect(Activity.where(company: other_company).count).to eq(0)
    end

    it 'prevents creation of invalid activities' do
      invalid_data = {
        user_id: user.id,
        activity_type: 'not_in_list',
        metadata: {},
        occurred_at: Time.current
      }
      
      expect {
        described_class.perform_now(invalid_data) rescue nil
      }.not_to change(Activity, :count)
    end
  end

  describe 'job configuration' do
    it 'uses the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end