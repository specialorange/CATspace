class FacebookUsersController < ApplicationController
  ensure_authenticated_to_facebook
     
  def setup_facebook_user
    @current_facebook_user  = facebook_session.user
  end
  
  def my
    render :action => "profile", :id => @fb_user.id
  end
  
  def profile
    if(params[:id])
      @user = FacebookUser.find(params[:id])
    else
      @user = @fb_user
    end
    @tags = @user.assignments.tag_counts
    @activity_items = @user.activity_items.sort{|a,b| b.created_at <=> a.created_at}
    if(@user.id == @fb_user.id)
      @self = true
    else
      @self = false
    end
  end  
  
  def list_assignments
    user = FacebookUser.find(params[:user])
    sort = params[:sort]
    if sort == 'title'
      sorted_assignments = user.assignments.sort {|a,b| a.title <=> b.title}
    elsif sort == 'date'
      sorted_assignments = user.assignments.sort {|a,b| b.created_at <=> a.created_at}
    elsif sort == 'rating'
      sorted_assignments = user.assignments.sort {|a,b| a.rating <=> b.rating}
    elsif sort == 'comments'
      sorted_assignments = user.assignments.sort {|a,b| a.title <=> b.title}
    else
      sorted_assignments = user.assignments
    end
    # user = facebook_session.user
    render :partial => "ajaxy_list", :locals => {:user => user, :assignments => sorted_assignments}, :layout => false
    #render :partial => "ajaxy_list", :layout => false    
  end  
  
  def preferences
  end
  
  def prefsave
      if @fb_user.update_attributes(params[:facebook_user])
        flash[:notice] = 'Your Preferences were successfully updated.'
        redirect_to(:action=>"preferences")
      else
        render :action => "preferences"
      end
  end
  
end