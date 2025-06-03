class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.boolean :activity_tracking_enabled, default: true, null: false
      t.jsonb :activity_tracking_config, default: {}

      t.timestamps
    end

    add_index :companies, :name, unique: true
    add_index :companies, :activity_tracking_enabled
  end
end
