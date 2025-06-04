# app/controllers/api/v1/admin/activities_controller.rb
module Api
  module V1
    module Admin
      class ActivitiesController < ApplicationController
        include Pagination

        before_action :authorize_admin!

        def index
          scope = Activity
            .includes(:user)
            .filter_by_params(filter_params)
            .recent

          paginated = paginate(scope)

          render json: {
            activities: serialize_activities(paginated[:records]),
            meta: paginated[:meta]
          }
        end

        def summary
          period = params[:period] || "day"
          group_by = params[:group_by] || "activity_type"

          summary_data = ActivitySummaryService.new(
            current_user.company,
            period: period,
            group_by: group_by
          ).generate

          render json: summary_data
        end

        def stats
          stats = {
            total_activities: Activity.count,
            activities_today: Activity.where("occurred_at >= ?", Date.current).count,
            activity_breakdown: Activity.group(:activity_type).count,
            recent_activities: Activity.recent.limit(10).map { |a| serialize_activity(a) }
          }

          render json: stats
        end

        private

        def filter_params
          params.permit(:user_id, :activity_type, :start_date, :end_date)
        end

        def serialize_activities(activities)
          activities.map { |activity| serialize_activity(activity) }
        end

        def serialize_activity(activity)
          {
            id: activity.id,
            user: serialize_user(activity.user),
            activity_type: activity.activity_type,
            metadata: activity.metadata.except("ip_address", "session_id"),
            occurred_at: activity.occurred_at.iso8601
          }
        end

        def serialize_user(user)
          return { id: nil, name: "[Deleted User]", email: "[Deleted]" } unless user

          {
            id: user.id,
            name: user.name,
            email: user.email,
            status: user.discarded? ? "deleted" : "active"
          }
        end
      end
    end
  end
end
