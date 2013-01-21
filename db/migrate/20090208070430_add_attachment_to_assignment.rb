class AddAttachmentToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :attachment_name, :string
    add_column :assignments, :queue_flag, :boolean, :default => false    
  end

  def self.down
    remove_column :assignments, :attachment_name
    remove_column :assignments, :queue_flag
  end
end
