class BuildDb < ActiveRecord::Migration
  def self.up

    add_column :facebook_users, :access_level, :tinyint, :default => 0

  end

  def self.down

    remove_column :facebook_users, :access_level

  end
end
