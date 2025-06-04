# spec/requests/api/v1/sessions_spec.rb
require 'rails_helper'

RSpec.describe 'Sessions API', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, email: 'test@example.com') }

  describe 'POST /api/v1/login' do
    context 'with valid credentials' do
      it 'returns success and tracks login activity' do
        expect {
          post '/api/v1/login', params: { email: user.email }
        }.to change(Activity, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Login successful')
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq(user.email)

        # Verify activity was tracked
        activity = Activity.last
        expect(activity.user).to eq(user)
        expect(activity.activity_type).to eq('login')
        expect(activity.metadata['login_method']).to eq('password')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized and does not track activity' do
        expect {
          post '/api/v1/login', params: { email: 'nonexistent@example.com' }
        }.not_to change(Activity, :count)

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end
    end

    context 'with discarded user' do
      before { user.discard }

      it 'returns unauthorized' do
        post '/api/v1/login', params: { email: user.email }

        expect(response).to have_http_status(:unauthorized)
        expect(Activity.count).to eq(0)
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    context 'when authenticated' do
      before do
        stub_authentication(user)
      end

      it 'returns success and tracks logout activity' do
        expect {
          delete '/api/v1/logout', headers: api_headers
        }.to change(Activity, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Logout successful')

        # Verify activity was tracked
        activity = Activity.last
        expect(activity.user).to eq(user)
        expect(activity.activity_type).to eq('logout')
        expect(activity.metadata['session_duration']).to be_present
      end
    end

    context 'when not authenticated' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate_with_token).and_return(nil)
      end

      it 'returns unauthorized and does not track activity' do
        expect {
          delete '/api/v1/logout'
        }.not_to change(Activity, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'activity tracking integration' do
    it 'tracks complete user session flow' do
      # Login
      post '/api/v1/login', params: { email: user.email }
      expect(response).to have_http_status(:ok)

      # Simulate some activity
      stub_authentication(user)

      # Logout
      delete '/api/v1/logout', headers: api_headers
      expect(response).to have_http_status(:ok)

      # Verify both activities
      activities = Activity.where(user: user).order(:occurred_at)
      expect(activities.count).to eq(2)
      expect(activities.map(&:activity_type)).to eq([ 'login', 'logout' ])
    end
  end
end
