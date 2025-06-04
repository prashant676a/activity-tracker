# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions

  before_action :authenticate_request
  before_action :set_tenant

  rescue_from ActsAsTenant::Errors::NoTenantSet do
    render json: { error: "Company not found" }, status: :not_found
  end

  private

  def authenticate_request
    @current_user = authenticate_with_token

    if @current_user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      false  # This stops the filter chain
    end
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
      false
    end
  end
end
