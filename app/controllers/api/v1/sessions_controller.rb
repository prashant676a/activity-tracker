# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_request
      skip_before_action :set_tenant

      # POST /api/v1/login
      def create
        user = User.kept.includes(:company).find_by(email: params[:email])
        
        if user.nil?
          render json: { error: "Invalid credentials" }, status: :unauthorized
          return
        end

        # In a real app, verify password here
        # For assessment, just demonstrate the flow
        
        # Track login activity - the service handles tenant setting
        ::ActivityTrackerService.track(
          user: user,
          activity_type: 'login',
          metadata: {
            login_method: 'password'
          },
          request: request
        )

        # Generate token (simplified for assessment)
        token = generate_token_for(user)

        render json: {
          message: "Login successful",
          token: token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role
          }
        }, status: :ok
      end

      # DELETE /api/v1/logout
      def destroy
        # In real app, invalidate the token
        if current_user
          # Track logout activity - the service handles tenant setting
          ::ActivityTrackerService.track(
            user: current_user,
            activity_type: 'logout',
            metadata: {
              session_duration: calculate_session_duration
            },
            request: request
          )

          render json: { message: "Logout successful" }, status: :ok
        else
          render json: { error: "Not authenticated" }, status: :unauthorized
        end
      end

      private

      def generate_token_for(user)
        # For assessment purposes, return a simple token
        # In production, use JWT or similar
        "demo-token-#{user.id}-#{Time.current.to_i}"
      end

      def calculate_session_duration
        # In a real app, calculate from session start time
        # For demo, return random duration
        "#{rand(10..120)} minutes"
      end
    end
  end
end