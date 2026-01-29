class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks, id: { type: :string, limit: 36 } do |t|
      t.string :anga_id, limit: 36, null: false
      t.string :url
      t.datetime :cached_at

      t.timestamps
    end

    add_index :bookmarks, :anga_id
    add_foreign_key :bookmarks, :angas
  end
end
