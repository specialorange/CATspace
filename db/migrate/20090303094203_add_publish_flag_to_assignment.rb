class AddPublishFlagToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :published, :boolean, :default => false  
  end

  def self.down
    remove_column :assignments, :published
  end
end
