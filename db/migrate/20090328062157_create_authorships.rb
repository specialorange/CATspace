class CreateAuthorships < ActiveRecord::Migration
  def self.up
    create_table :authorships do |t|
      t.integer :facebook_user_uid, :null => false
      t.integer :assignment_id, :null => false
      t.integer :role, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :authorships
  end
end
