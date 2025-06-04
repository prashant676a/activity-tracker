# app/controllers/concerns/development_auth.rb
module DevelopmentAuth
  extend ActiveSupport::Concern

  included do
    if Rails.env.development? || Rails.env.test?
      before_action :set_dev_auth_header
    end
  end

  private

  def set_dev_auth_header
    # Allow token via query parameter in development
    if params[:auth_token].present? && request.headers["Authorization"].blank?
      request.headers["Authorization"] = "Bearer #{params[:auth_token]}"
    end

    # Auto-set dummy token if no auth provided at all
    if request.headers["Authorization"].blank? && params[:dev_mode] == "true"
      request.headers["Authorization"] = "Bearer dummy-token"
    end
  end
end
