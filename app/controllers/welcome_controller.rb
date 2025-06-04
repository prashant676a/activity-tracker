# app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController
  # Skip authentication for public endpoints
  skip_before_action :authenticate_request
  skip_before_action :set_tenant

  def index
    base_url = request.base_url

    # In development, include ready-to-use URLs with auth
    if Rails.env.development? || Rails.env.test?
      render json: {
        name: "Activity Tracker API",
        version: "1.0.0",
        status: "operational",
        environment: Rails.env,
        health: "/up",

        # Authentication endpoints
        auth_endpoints: {
          login: {
            method: "POST",
            url: "#{base_url}/api/v1/login",
            example: "curl -X POST #{base_url}/api/v1/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@techcorp.com\"}'"
          },
          logout: {
            method: "DELETE",
            url: "#{base_url}/api/v1/logout",
            example: "curl -X DELETE #{base_url}/api/v1/logout -H 'Authorization: Bearer dummy-token'"
          }
        },

        # Include ready-to-use URLs for development
        quick_links: {
          message: "Copy and paste these URLs in your browser (dev mode only):",
          activities: "#{base_url}/api/v1/admin/activities?dev_mode=true",
          activities_paginated: "#{base_url}/api/v1/admin/activities?dev_mode=true&per_page=5&page=1",
          summary: "#{base_url}/api/v1/admin/activities/summary?dev_mode=true",
          stats: "#{base_url}/api/v1/admin/activities/stats?dev_mode=true",

          # With explicit token
          with_token: {
            activities: "#{base_url}/api/v1/admin/activities?auth_token=dummy-token",
            summary: "#{base_url}/api/v1/admin/activities/summary?auth_token=dummy-token&period=week&group_by=user",
            stats: "#{base_url}/api/v1/admin/activities/stats?auth_token=dummy-token"
          }
        },

        # Include curl examples
        examples: {
          curl: {
            login: "curl -X POST #{base_url}/api/v1/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@techcorp.com\"}'",
            activities: "curl -H 'Authorization: Bearer dummy-token' #{base_url}/api/v1/admin/activities",
            logout: "curl -X DELETE #{base_url}/api/v1/logout -H 'Authorization: Bearer dummy-token'"
          },

          javascript: {
            login: "fetch('#{base_url}/api/v1/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'admin@techcorp.com' }) }).then(r => r.json()).then(console.log)",
            fetch_activities: "fetch('#{base_url}/api/v1/admin/activities', { headers: { 'Authorization': 'Bearer dummy-token' } }).then(r => r.json()).then(console.log)"
          }
        },

        test_user: {
          email: "admin@techcorp.com",
          note: "Use this email to test login endpoint"
        }
      }
    else
      # Production response without dev links
      render json: {
        name: "Activity Tracker API",
        version: "1.0.0",
        status: "operational"
      }
    end
  end
end
