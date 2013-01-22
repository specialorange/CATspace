class HomeController < ApplicationController

  def index
    @activity_items = ActivityItem.find(:all, :order => "created_at DESC", :limit => 10)
    @recommended_assignments = Assignment.find(:all, :conditions => ["facebook_user_id != ?", @fb_user.id ], :order => "created_at DESC", :limit => 5)
    @tags = Tag.counts
    @users_like_you = FacebookUser.find(:all, :conditions => ["id != ?", @fb_user.id ], :order => "created_at DESC", :limit => 5)
  end  
end