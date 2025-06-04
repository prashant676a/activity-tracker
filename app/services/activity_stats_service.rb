# app/services/activity_stats_service.rb
class ActivityStatsService
  def initialize(company)
    @company = company
  end

  def generate
    ActsAsTenant.with_tenant(@company) do
      {
        overview: overview_stats,
        user_stats: user_stats,
        activity_trends: activity_trends,
        peak_times: peak_times
      }
    end
  end

  private

  def overview_stats
    {
      total_activities: Activity.count,
      activities_today: Activity.where("occurred_at >= ?", Date.current).count,
      active_users_today: Activity
        .where("occurred_at >= ?", Date.current)
        .distinct.count(:user_id),
      activities_this_week: Activity
        .where("occurred_at >= ?", 1.week.ago)
        .count
    }
  end

  def user_stats
    {
      total_users: User.kept.count,
      active_users_this_week: Activity
        .where("occurred_at >= ?", 1.week.ago)
        .distinct.count(:user_id),
      most_active_users: Activity
        .group(:user_id)
        .count
        .sort_by { |_, count| -count }
        .first(5)
        .map { |user_id, count|
          user = User.find(user_id)
          { id: user_id, name: user.name, activity_count: count }
        }
    }
  end

  def activity_trends
    Activity
      .where("occurred_at >= ?", 7.days.ago)
      .group("DATE(occurred_at)")
      .group(:activity_type)
      .count
      .group_by { |(date, _), _| date }
      .transform_values { |counts|
        counts.transform_keys { |(_, type), _| type }
              .transform_values { |_, count| count }
      }
  end

  def peak_times
    Activity
      .where("occurred_at >= ?", 7.days.ago)
      .group("EXTRACT(HOUR FROM occurred_at)")
      .count
      .transform_keys(&:to_i)
      .sort_by { |hour, _| hour }
  end
end
