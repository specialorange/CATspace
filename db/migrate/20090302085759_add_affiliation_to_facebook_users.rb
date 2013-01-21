class AddAffiliationToFacebookUsers < ActiveRecord::Migration
  def self.up
    add_column :facebook_users, :affiliation, :string
  end

  def self.down
    remove_column :facebook_users, :affiliation
  end
end
