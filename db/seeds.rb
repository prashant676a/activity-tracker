puts "🌱 Seeding database..."
puts "=" * 50

# Create Companies
puts "\n📢 Creating companies..."

tech_corp = Company.create!(
  name: "TechCorp",
  activity_tracking_enabled: true,
  activity_tracking_config: {
    enabled_activity_types: Activity::ACTIVITY_TYPES,
    retention_days: 730
  }
)

startup_inc = Company.create!(
  name: "StartupInc",
  activity_tracking_enabled: true,
  activity_tracking_config: {
    enabled_activity_types: [ 'login', 'logout', 'profile_update' ],
    retention_days: 365
  }
)

enterprise_co = Company.create!(
  name: "EnterpriseCo",
  activity_tracking_enabled: false  # Tracking disabled
)

puts "✅ Created #{Company.count} companies"

# Create Users
puts "\n👥 Creating users..."

# TechCorp users
tech_admin = User.create!(
  company: tech_corp,
  email: "admin@techcorp.com",
  name: "Alice Admin",
  role: "company_admin"
)

tech_users = []
5.times do |i|
  tech_users << User.create!(
    company: tech_corp,
    email: "user#{i + 1}@techcorp.com",
    name: Faker::Name.name,
    role: "user"
  )
end

# Create a discarded user
discarded_user = User.create!(
  company: tech_corp,
  email: "former@techcorp.com",
  name: "Former Employee",
  role: "user"
)
discarded_user.discard

# StartupInc users
startup_admin = User.create!(
  company: startup_inc,
  email: "admin@startupinc.com",
  name: "Bob Boss",
  role: "company_admin"
)

startup_users = []
3.times do |i|
  startup_users << User.create!(
    company: startup_inc,
    email: "user#{i + 1}@startupinc.com",
    name: Faker::Name.name,
    role: "user"
  )
end

# EnterpriseCo users (even though tracking is disabled)
enterprise_admin = User.create!(
  company: enterprise_co,
  email: "admin@enterpriseco.com",
  name: "Carol Corporate",
  role: "company_admin"
)

# System admin
system_admin = User.create!(
  company: tech_corp,
  email: "system@admin.com",
  name: "System Admin",
  role: "admin"
)

puts "✅ Created #{User.count} users (including #{User.discarded.count} discarded)"

# Create Activities
puts "\n📊 Creating activities..."

# Helper method to create realistic metadata
def login_metadata
  {
    ip_address: Faker::Internet.ip_v4_address,
    user_agent: Faker::Internet.user_agent,
    location: Faker::Address.country,
    browser: [ 'Chrome', 'Firefox', 'Safari', 'Edge' ].sample,
    device: [ 'Desktop', 'Mobile', 'Tablet' ].sample
  }
end

def recognition_metadata(users)
  {
    recipient_user_id: users.sample.id,
    points: [ 10, 25, 50, 100 ].sample,
    category: [ 'teamwork', 'innovation', 'leadership', 'customer_service' ].sample,
    message: Faker::Lorem.sentence(word_count: 10)
  }
end

# Generate activities for the past 30 days
all_users = tech_users + [ tech_admin ] + startup_users + [ startup_admin ]

all_users.each do |user|
  # Skip if company has tracking disabled
  next unless user.company.activity_tracking_enabled?

  # Generate varied activity patterns
  days_active = rand(20..30)

  days_active.times do |day|
    date = day.days.ago

    # Morning login
    if rand < 0.9  # 90% chance of logging in
      Activity.create!(
        user: user,
        company: user.company,
        activity_type: 'login',
        occurred_at: date.beginning_of_day + rand(7..10).hours,
        metadata: login_metadata
      )

      # Activities during the day
      if rand < 0.3  # 30% chance of profile update
        Activity.create!(
          user: user,
          company: user.company,
          activity_type: 'profile_update',
          occurred_at: date.beginning_of_day + rand(10..14).hours,
          metadata: {
            changed_fields: [ 'title', 'department', 'phone', 'avatar' ].sample(rand(1..2)),
            ip_address: Faker::Internet.ip_v4_address
          }
        )
      end

      # Recognition activities (only for TechCorp)
      if user.company == tech_corp && rand < 0.2  # 20% chance
        other_users = (tech_users + [ tech_admin ]) - [ user ]
        recipient = other_users.sample

        # Give recognition
        recognition_data = recognition_metadata(other_users)
        Activity.create!(
          user: user,
          company: user.company,
          activity_type: 'give_recognition',
          occurred_at: date.beginning_of_day + rand(11..16).hours,
          metadata: recognition_data
        )

        # Receive recognition
        Activity.create!(
          user: recipient,
          company: recipient.company,
          activity_type: 'receive_recognition',
          occurred_at: date.beginning_of_day + rand(11..16).hours + 1.minute,
          metadata: {
            giver_user_id: user.id,
            points: recognition_data[:points],
            category: recognition_data[:category],
            message: recognition_data[:message]
          }
        )
      end

      # Evening logout
      if rand < 0.85  # 85% chance of logging out
        Activity.create!(
          user: user,
          company: user.company,
          activity_type: 'logout',
          occurred_at: date.beginning_of_day + rand(16..20).hours,
          metadata: {
            session_duration: rand(6..10).hours.to_i,
            ip_address: Faker::Internet.ip_v4_address
          }
        )
      end
    end
  end
end

# Admin actions (for admins only)
[ tech_admin, startup_admin, system_admin ].each do |admin|
  next unless admin.company.activity_tracking_enabled?

  5.times do
    Activity.create!(
      user: admin,
      company: admin.company,
      activity_type: 'admin_action',
      occurred_at: rand(1..15).days.ago,
      metadata: {
        action: [ 'reset_password', 'change_role', 'update_permissions', 'view_reports' ].sample,
        target_user_id: admin.company.users.where.not(id: admin.id).sample&.id,
        ip_address: Faker::Internet.ip_v4_address,
        details: Faker::Lorem.sentence
      }
    )
  end
end

# Create some activities for the discarded user (before they were discarded)
10.times do |i|
  Activity.create!(
    user: discarded_user,
    company: discarded_user.company,
    activity_type: [ 'login', 'logout', 'profile_update' ].sample,
    occurred_at: rand(31..60).days.ago,
    metadata: {
      ip_address: Faker::Internet.ip_v4_address,
      note: "Historical activity before user was discarded"
    }
  )
end

puts "✅ Created #{Activity.count} activities"

# Summary Statistics
puts "\n📈 Summary Statistics:"
puts "=" * 50

Company.all.each do |company|
  puts "\n#{company.name}:"
  puts "  - Users: #{company.users.kept.count} active, #{company.users.discarded.count} discarded"
  puts "  - Activities: #{company.activities.count} total"
  puts "  - Tracking: #{company.activity_tracking_enabled? ? 'Enabled' : 'Disabled'}"

  if company.activities.any?
    puts "  - Activity breakdown:"
    company.activities.group(:activity_type).count.each do |type, count|
      puts "    • #{type}: #{count}"
    end
    puts "  - Date range: #{company.activities.minimum(:occurred_at).to_date} to #{company.activities.maximum(:occurred_at).to_date}"
  end
end

# Test Credentials
puts "\n🔑 Test Credentials:"
puts "=" * 50
puts "Company Admins:"
puts "  - admin@techcorp.com (TechCorp)"
puts "  - admin@startupinc.com (StartupInc)"
puts "  - admin@enterpriseco.com (EnterpriseCo - tracking disabled)"
puts "\nSystem Admin:"
puts "  - system@admin.com"
puts "\nRegular Users:"
puts "  - user1@techcorp.com through user5@techcorp.com"
puts "  - user1@startupinc.com through user3@startupinc.com"
puts "\nDiscarded User:"
puts "  - former@techcorp.com (soft deleted)"

# API Examples
puts "\n🚀 API Test Examples:"
puts "=" * 50
puts "# Get all activities:"
puts "curl -H 'Authorization: Bearer demo-token' http://localhost:3000/api/v1/admin/activities"
puts "\n# Filter by activity type:"
puts "curl -H 'Authorization: Bearer demo-token' http://localhost:3000/api/v1/admin/activities?activity_type=login"
puts "\n# Filter by date range:"
puts "curl -H 'Authorization: Bearer demo-token' http://localhost:3000/api/v1/admin/activities?start_date=#{7.days.ago.to_date}&end_date=#{Date.current}"
puts "\n# Get specific user's activities:"
puts "curl -H 'Authorization: Bearer demo-token' http://localhost:3000/api/v1/admin/activities?user_id=#{tech_users.first.id}"

puts "\n✅ Seeding complete!"
puts "=" * 50
