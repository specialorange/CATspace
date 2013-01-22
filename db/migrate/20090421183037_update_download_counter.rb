class UpdateDownloadCounter < ActiveRecord::Migration
  def self.up
    change_column :assignments, :stat_downloads, :bigint, :default => 0
  end

  def self.down
    change_column :assignments, :stat_downloads, :bigint
  end
end
