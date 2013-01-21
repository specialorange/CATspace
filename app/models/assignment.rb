require_dependency "search"

class Assignment < ActiveRecord::Base
  
  acts_as_taggable
  acts_as_rateable
  
  belongs_to :facebook_user, :foreign_key => :facebook_user_id, :class_name => "FacebookUser"
  has_many :comments
  has_many :activity_items
  
  validates_presence_of :title, :on => :create, :message => "can't be blank"
  
  searches_on :title, :synopsis
  
end
