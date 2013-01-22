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
    @activity_items = @user.activity_items.sort{|a,b| b.created_at <=> a.created_at}.first(5)
    @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => @user.id },:order => 'created_at DESC'
    
    if(@user.id == @fb_user.id)
      @self = true
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => @user.id },:order => 'created_at DESC'
    else
      @self = false
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => @user.id, :published => true },:order => 'created_at DESC'
    end
  end  
  
  def index
    if(params[:id])
      @user = FacebookUser.find(params[:id])
    else
      @user = @fb_user
    end
    
    if(@user.id == @fb_user.id)
      @self = true
    else
      @self = false
    end

    @allUsers = FacebookUser.all
    @catspaceUsers = []
    @facebookerUsers = @user.friends_with_this_app

    # TODO: Low priority - make more efficient
    @facebookerUsers.each { |facebooker_user| 
      logger.debug { "[DEBUG] #{facebooker_user.class}" }
      cUser = FacebookUser.find(:first, :conditions => { :uid => facebooker_user.id })
      if cUser
        @catspaceUsers << cUser
      else
        logger.info { "[INFO] This user is screwing up the DB (Showing UID): #{facebooker_user.id}" }
      end
    }
    
  end
  
  def list_assignments
    user = FacebookUser.find(params[:user])
    sort = params[:sort]
    if sort == 'title'
      sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => user.id },:order => 'title ASC'
    elsif sort == 'date'
      sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => user.id },:order => 'created_at DESC'
    elsif sort == 'rating'
      sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => user.id },:order => 'rating DESC'
    elsif sort == 'comments'
      sorted_assignments = user.assignments.sort {|a,b| b.comments.count <=> a.comments.count}
    else
      sorted_assignments = Assignment.paginate :page => params[:page], :conditions => {:facebook_user_id => user.id },:order => 'created_at DESC'
    end
    render :partial => "ajaxy_list", :locals => {:user => user, :assignments => sorted_assignments, :sort => sort}, :layout => false
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