class HomeController < ApplicationController

  def index
    @activity_items = ActivityItem.find(:all, :order => "created_at DESC", :limit => 10) 
    
    # TODO: stronger recommendation system. Right now is just by tag subscription   
    @subscribedTags = @fb_user.tag_list
    @recommended_assignments = Assignment.find_tagged_with(@subscribedTags, :limit => 5, :conditions => {:published => true})
    @recommended_assignments.reject! { |assignment|
      assignment.facebook_user == @fb_user or assignment.is_author? @fb_user
    }
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
  
  def list_assignments
    user = FacebookUser.find(params[:user])
    sort = params[:sort]

    if sort == 'recoms'
      # TODO What are we going to do for recommendations
      sorted_assignments = Assignment.find(:all, :conditions => ["published = true and facebook_user_id != ?", @fb_user.id ], :order => "created_at DESC", :limit => 5)
    elsif sort == 'rated'
      sorted_assignments = Assignment.find(:all, :conditions => ["published = true and facebook_user_id != ?", @fb_user.id ], :order => 'rating DESC')
    elsif sort == 'downloads'
      sorted_assignments = Assignment.find(:all, :conditions => [ "published = true and facebook_user_id != ?", @fb_user.id ], :order => 'stat_downloads DESC', :limit => 5)
    else
      sorted_assignments = user.assignments
    end
    
    render :partial => "ajaxy_list", :locals => {:user => user, :assignments => sorted_assignments, :sort => sort}, :layout => false
  end
  
end