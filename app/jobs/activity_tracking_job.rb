# app/jobs/activity_tracking_job.rb
class ActivityTrackingJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform(activity_data)
    company_id = User.find(activity_data[:user_id]).company_id

    ActsAsTenant.with_tenant(Company.find(company_id)) do
      Activity.create!(activity_data)
    end
  end
end
