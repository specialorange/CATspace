class CreateDownloadItems < ActiveRecord::Migration
  def self.up
    create_table :download_items do |t|
      t.integer :facebook_user_id
      t.integer :assignment_id
      t.string :path
      t.string :key

      t.timestamps
    end
  end

  def self.down
    drop_table :download_items
  end
end
