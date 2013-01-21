class CreateActivityItems < ActiveRecord::Migration
  def self.up
    create_table :activity_items do |t|
      t.column(:facebook_user_id, :integer, :null => false)
      t.column(:assignment_id, :integer, :null => false)
      t.column(:sentence, :string, :null => false)
      t.timestamps
    end
  end

  def self.down
    drop_table :activity_items
  end
end
