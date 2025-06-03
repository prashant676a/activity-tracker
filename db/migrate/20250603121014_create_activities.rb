class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :activity_type, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    # Essential indexes for performance
    add_index :activities, :activity_type
    add_index :activities, :occurred_at
    add_index :activities, [ :company_id, :occurred_at ] # For company-scoped queries
    add_index :activities, [ :user_id, :activity_type ]  # For user activity history
    add_index :activities, [ :company_id, :activity_type, :occurred_at ],
              name: 'index_activities_on_company_type_and_time' # For filtered analytics

    # GIN index for JSONB queries
    add_index :activities, :metadata, using: :gin

    # Add check constraint for valid activity types
    execute <<-SQL
      ALTER TABLE activities
      ADD CONSTRAINT valid_activity_type
      CHECK (activity_type IN ('login', 'logout', 'give_recognition', 'receive_recognition', 'profile_update', 'admin_action'))
    SQL
  end
end
