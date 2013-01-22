class DownloadCounter < ActiveRecord::Migration
  def self.up
    add_column :assignments, :stat_downloads, :bigint
  end

  def self.down
    remove_column :assignments, :stat_downloads
  end
end
