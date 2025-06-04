# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions
  include DevelopmentAuth # Add this for dev-only auth helpers

  before_action :authenticate_request, unless: :public_endpoint?
  before_action :set_tenant, unless: :public_endpoint?

  rescue_from ActsAsTenant::Errors::NoTenantSet do
    render json: { error: "Company not found" }, status: :not_found
  end

  private

  def public_endpoint?
    # Define public endpoints that don't require authentication
    public_paths = [ "/", "/up", "/docs", "/api/v1/health" ]
    public_paths.include?(request.path)
  end

  def authenticate_request
    @current_user = authenticate_with_token

    if @current_user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      false  # This stops the filter chain
    end

    true
  end

  def authenticate_with_token
    return @current_user if defined?(@current_user)

    token = request.headers["Authorization"]&.split(" ")&.last
    return nil unless token.present?

    # For testing/demo - in production use real auth
    if Rails.env.test? || Rails.env.development?
      User.includes(:company).find_by(email: "admin@techcorp.com") ||
        User.joins(:company).where(role: [ "admin", "company_admin" ]).first
    else
      # Real JWT/OAuth implementation here
      nil
    end
  end

  def current_user
    @current_user
  end

  def set_tenant
    if current_user && current_user.company
      ActsAsTenant.current_tenant= current_user.company
    end
  end

  def authorize_admin!
    unless current_user&.can_view_activities?
      render json: { error: "Forbidden" }, status: :forbidden
      return false
    end
    true
  end
end
