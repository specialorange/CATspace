class ActivityItem < ActiveRecord::Base
  belongs_to :facebook_user
  belongs_to :assignment
end
