# app/services/activity_tracker.rb
class ActivityTrackerService
  class TrackingError < StandardError; end
  class << self
    def track(user:, activity_type:, metadata: {}, request: nil)
      return result(false, "User required") unless user
      return result(false, "Invalid activity type") unless valid_activity_type?(activity_type)

      # acts_as_tenant ensures company scoping
      ActsAsTenant.with_tenant(user.company) do
        return result(false, "Tracking disabled") unless tracking_enabled?(user, activity_type)

        activity_data = build_activity_data(user, activity_type, metadata, request)

        if should_process_async?(user.company)
          ActivityTrackingJob.perform_later(activity_data)
          result(true, "Activity queued")
        else
          activity = Activity.create!(activity_data)
          result(true, "Activity tracked", activity)
        end
      end
    rescue StandardError => e
      handle_error(e, user, activity_type)
      result(false, e.message)
    end

    def track!(user:, activity_type:, metadata: {}, request: nil)
      result = track(user: user, activity_type: activity_type, metadata: metadata, request: request)
      raise TrackingError, result[:message] unless result[:success]
      result
    end

    def bulk_track(activities_data)
      ActsAsTenant.without_tenant do  # Handle multiple tenants
        results = activities_data.map do |data|
          user = User.find_by(id: data[:user_id])
          next { success: false, error: "User not found" } unless user

          track(
            user: user,
            activity_type: data[:activity_type],
            metadata: data[:metadata]
          )
        end

        {
          total: activities_data.size,
          succeeded: results.count { |r| r[:success] },
          failed: results.count { |r| !r[:success] },
          results: results
        }
      end
    end

    private

    def result(success, message, data = nil)
      { success: success, message: message, data: data }.compact
    end

    def valid_activity_type?(type)
      Activity::ACTIVITY_TYPES.include?(type.to_s)
    end

    def tracking_enabled?(user, activity_type)
      user.company.tracking_enabled_for?(activity_type)
    end

    def should_process_async?(company)
      # Could be based on company settings or system load
      company.activities.where("created_at > ?", 1.hour.ago).count > 1000
    end

    def build_activity_data(user, activity_type, metadata, request)
      {
        user_id: user.id,
        activity_type: activity_type.to_s,
        metadata: enrich_metadata(metadata, request),
        occurred_at: Time.current
      }
    end

    def enrich_metadata(metadata, request)
      enriched = metadata.dup

      if request
        enriched.merge!(
          ip_address: anonymize_ip(request.remote_ip),
          user_agent: request.user_agent,
          request_id: request.request_id
        )
      end

      enriched
    end

    def anonymize_ip(ip)
      return nil if ip.blank?
      parts = ip.split(".")
      return ip unless parts.length == 4
      "#{parts[0]}.#{parts[1]}.#{parts[2]}.0"
    end

    def handle_error(error, user, activity_type)
      Rails.logger.error({
        error: "Activity tracking failed",
        user_id: user&.id,
        company_id: user&.company_id,
        activity_type: activity_type,
        error_class: error.class.name,
        error_message: error.message,
        backtrace: error.backtrace&.first(5)
      }.to_json)

      # Could notify error tracking service
      # Sentry.capture_exception(error, extra: { user_id: user&.id })
    end
  end
end
