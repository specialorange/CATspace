class AddPrefCommentNotifyToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :pref_comment_notify, :boolean, :default => false
  end

  def self.down
    remove_column :assignments, :pref_comment_notify
  end
end
