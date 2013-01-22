class ActivityItem < ActiveRecord::Base

  #Constant Definitions
  #Note: Be very careful with these. If you change them, you need to manually change the string as it is stored in the databse.
  #TODO: Change this such that a numeric transaction code is stored in the DB in place of the actual string.
  CreateAssignmentString = "created "
  UpdateAssignmentString = "updated "
  CommentAssignmentString = "commented on "
  TagAssignmentString = "tagged "
  
  belongs_to :facebook_user
  belongs_to :assignment
end
