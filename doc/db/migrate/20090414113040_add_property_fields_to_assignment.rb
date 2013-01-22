class AddPropertyFieldsToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :prop_language, :string
    add_column :assignments, :prop_language_version, :string
    add_column :assignments, :prop_license, :string
    add_column :assignments, :prop_license_url, :string
    add_column :assignments, :prop_course, :string
    add_column :assignments, :prop_info_url, :string
    add_column :assignments, :prop_estimated_experience, :string
    add_column :assignments, :prop_estimated_time, :string
    add_column :assignments, :prop_estimated_size, :string
    add_column :assignments, :prop_copyright, :string
  end

  def self.down
    remove_column :assignments, :prop_language
    remove_column :assignments, :prop_language_version
    remove_column :assignments, :prop_license
    remove_column :assignments, :prop_license_url
    remove_column :assignments, :prop_course
    remove_column :assignments, :prop_info_url
    remove_column :assignments, :prop_estimated_experience
    remove_column :assignments, :prop_estimated_time
    remove_column :assignments, :prop_estimated_size
    remove_column :assignments, :prop_copyright
  end
end
