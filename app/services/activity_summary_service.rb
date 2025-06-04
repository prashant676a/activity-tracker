# app/services/activity_summary_service.rb
class ActivitySummaryService
  def initialize(company, period: "day", group_by: "activity_type")
    @company = company
    @period = period
    @group_by = group_by
  end

  def generate
    ActsAsTenant.with_tenant(@company) do
      {
        period: @period,
        group_by: @group_by,
        start_date: start_date,
        end_date: end_date,
        data: calculate_summary,
        generated_at: Time.current
      }
    end
  end

  private

  def calculate_summary
    case @group_by
    when "activity_type"
      Activity.between(start_date, end_date).group(:activity_type).count
    when "user"
      Activity
        .between(start_date, end_date)
        .joins(:user)
        .group("users.email")
        .count
    when "hour"
      Activity
        .between(start_date, end_date)
        .group("EXTRACT(HOUR FROM occurred_at)")
        .count
        .transform_keys(&:to_i)
    else
      { total: Activity.between(start_date, end_date).count }
    end
  end

  def start_date
    case @period
    when "hour" then 1.hour.ago
    when "day" then 1.day.ago
    when "week" then 1.week.ago
    when "month" then 1.month.ago
    else 1.day.ago
    end
  end

  def end_date
    Time.current
  end
end
