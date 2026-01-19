class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :email_address, null: false
      t.string :password_digest

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
