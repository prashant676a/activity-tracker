# app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController
  skip_before_action :authenticate_request
  skip_before_action :set_tenant

  def index
    render json: {
      name: "Activity Tracker API",
      version: "1.0.0",
      status: "operational",
      endpoints: {
        activities: "/api/v1/admin/activities",
        summary: "/api/v1/admin/activities/summary",
        stats: "/api/v1/admin/activities/stats"
      },
      documentation: "/docs",
      health: "/up"
    }
  end
end
