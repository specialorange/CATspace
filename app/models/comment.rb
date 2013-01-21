class Comment < ActiveRecord::Base
  
  validates_presence_of :body
  validates_presence_of :facebook_user_id
  validates_presence_of :assignment_id  

  belongs_to :assignment
  belongs_to :facebook_user
end
