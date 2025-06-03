class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :company, null: false, foreign_key: true
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, default: 'user', null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, [:company_id, :email], unique: true
    add_index :users, :discarded_at
    add_index :users, [:company_id, :role]
  end
end
