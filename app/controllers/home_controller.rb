class HomeController < ApplicationController

  def index
    @activity_items = ActivityItem.find(:all, :order => "created_at DESC", :limit => 10)
    @recommended_assignments = Assignment.find(:all, :conditions => ["facebook_user_id != ?", @fb_user.id ], :order => "created_at DESC", :limit => 5)
    @userTags = FacebookUser.tag_counts 
    @assignmentTags = Assignment.tag_counts
    # Tags of interest means that there are tags related to the tags the current user is
    # followiing, which he/she is not following. For now, this only shows tags that 
    # the current user is NOT following, but the relationship between tags is not determined.
    @assignmentTags.reject! { |assignmentTag| 
      @userTags.include? assignmentTag
    }
    @users_like_you = FacebookUser.find(:all, :conditions => ["id != ?", @fb_user.id ], :order => "created_at DESC", :limit => 5)
  end  
end