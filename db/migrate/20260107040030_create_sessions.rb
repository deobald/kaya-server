class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.string :user_id, limit: 36, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :sessions, :user_id
    add_foreign_key :sessions, :users
  end
end
