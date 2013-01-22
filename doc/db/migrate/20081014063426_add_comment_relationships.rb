class AddCommentRelationships < ActiveRecord::Migration
  def self.up
    add_column :comments, :facebook_user_id, :integer, :null => false
    add_column :comments, :assignment_id, :integer, :null => false    
  end

  def self.down
    remove_column :comments, :facebook_user_id
    remove_column :comments, :assignment_id  
  end
end
