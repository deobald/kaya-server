class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.string :user_id, limit: 36, null: false
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_index :identities, :user_id
    add_index :identities, [:provider, :uid], unique: true
    add_foreign_key :identities, :users
  end
end
