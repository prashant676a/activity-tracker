# spec/requests/api/v1/admin/activities_spec.rb
require 'rails_helper'

RSpec.describe 'Admin Activities API', type: :request do
  let(:company) { create(:company) }
  let(:admin) { create(:user, :company_admin, company: company) }

  before do
    stub_authentication(admin)
    # Ensure tenant is set for all tests
    ActsAsTenant.current_tenant = company
  end

  after do
    # Clean up tenant after each test
    ActsAsTenant.current_tenant = nil
  end

  describe 'GET /api/v1/admin/activities' do
    let!(:activities) do
      # Create activities within the current tenant context
      create_list(:activity, 3, user: admin)
    end

    it 'returns activities for the current tenant' do
      get '/api/v1/admin/activities', headers: api_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['activities'].size).to eq(3)
    end

    it 'does not return activities from other tenants' do
      # First, clear any existing tenant context
      ActsAsTenant.current_tenant = nil

      # Create other company and user
      other_company = create(:company)
      other_user = create(:user, company: other_company)

      # Set tenant to other company and create activity
      ActsAsTenant.current_tenant = other_company
      other_activity = Activity.create!(
        user: other_user,
        activity_type: 'login',
        occurred_at: Time.current,
        metadata: {}
      )

      # Clear tenant again before making request
      ActsAsTenant.current_tenant = nil

      # Make request - controller will set tenant to admin's company
      get '/api/v1/admin/activities', headers: api_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['activities'].size).to eq(3) # Only our company's activities

      # Verify the other activity exists but wasn't returned
      expect(Activity.unscoped.exists?(other_activity.id)).to be true
    end

    context 'with filters' do
      let!(:login_activity) { create(:activity, :login, user: admin) }
      let!(:logout_activity) { create(:activity, :logout, user: admin) }

      it 'filters by activity type' do
        get '/api/v1/admin/activities', params: { activity_type: 'login' }, headers: api_headers

        json = JSON.parse(response.body)
        expect(json['activities'].size).to eq(4) # 3 already created 1 in this context
        expect(json['activities'].first['activity_type']).to eq('login')
      end
    end

    context 'pagination' do
      before do
        # Create 30 activities in addition to the 3 already created
        create_list(:activity, 27, user: admin)
      end

      it 'paginates results' do
        get '/api/v1/admin/activities', params: { per_page: 10, page: 2 }, headers: api_headers

        json = JSON.parse(response.body)
        expect(json['activities'].size).to eq(10)
        expect(json['meta']['current_page']).to eq(2)
        expect(json['meta']['total_count']).to eq(30)
      end
    end
  end

  describe 'GET /api/v1/admin/activities/summary' do
    before do
      create_list(:activity, 5, :login, user: admin, occurred_at: 1.hour.ago)
      create_list(:activity, 3, :logout, user: admin, occurred_at: 2.hours.ago)
    end

    it 'returns activity summary' do
      get '/api/v1/admin/activities/summary', headers: api_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['group_by']).to eq('activity_type')
      expect(json['data']['login']).to eq(5)
      expect(json['data']['logout']).to eq(3)
    end
  end

  describe 'GET /api/v1/admin/activities/stats' do
    it 'returns activity statistics' do
      create_list(:activity, 5, user: admin)

      get '/api/v1/admin/activities/stats', headers: api_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('total_activities')
      expect(json).to have_key('activities_today')
      expect(json).to have_key('activity_breakdown')
      expect(json['total_activities']).to eq(5)
    end
  end

  describe 'authorization' do
    context 'as regular user' do
      let(:regular_user) { create(:user, company: company, role: 'user') }

      before do
        stub_authentication(regular_user)
      end

      it 'returns forbidden' do
        get '/api/v1/admin/activities', headers: api_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as unauthenticated user' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate_with_token).and_return(nil)
      end

      it 'returns unauthorized' do
        get '/api/v1/admin/activities'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
