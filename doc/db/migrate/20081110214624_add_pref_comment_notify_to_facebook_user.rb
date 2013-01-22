class AddPrefCommentNotifyToFacebookUser < ActiveRecord::Migration
  def self.up
    add_column :facebook_users, :pref_comment_notify, :boolean, :default => false
  end

  def self.down
    remove_column :facebook_users, :pref_comment_notify
  end
end
