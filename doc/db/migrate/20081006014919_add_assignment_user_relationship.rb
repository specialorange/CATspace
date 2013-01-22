class AddAssignmentUserRelationship < ActiveRecord::Migration
  def self.up
    add_column :assignments, :facebook_user_id, :integer, :null => false
  end

  def self.down
    remove_column :assignments, :facebook_user_id
  end
end
