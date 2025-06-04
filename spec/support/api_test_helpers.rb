# spec/support/api_test_helpers.rb
module ApiTestHelpers
  def stub_authentication(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_with_token).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    # ActsAsTenant.current_tenant = user.company
  end

  def api_headers(token = 'test-token')
    { 'Authorization' => "Bearer #{token}" }
  end
end
