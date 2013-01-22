class AssignmentsController < ApplicationController

  # GET /assignments
  # GET /assignments.xml
  # moved sort code to the index because pagination does not work in ajax when using it with facebooker
  def index
    sort = params[:sort]
    if sort == 'latest'
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'updated_at DESC'
    # TODO download count not available yet
    elsif sort == 'downloads'
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'UPPER(title) ASC'
    elsif sort == 'rating'
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'rating ASC'
    elsif sort == 'mostRatings'
      @sorted_assignments = (Assignment.paginate :page => params[:page], :conditions => { :published => true }).sort {|a,b| b.ratings.length <=> a.ratings.length}
    elsif sort == 'mostComments'
      @sorted_assignments = (Assignment.paginate :page => params[:page], :conditions => { :published => true }).sort {|a,b| b.comments.length <=> a.comments.length}
    else  
      @sorted_assignments = Assignment.paginate :page => params[:page], :order => 'updated_at DESC'
    end
    # render :partial => "ajaxy_list", :locals => {:assignments => sorted_assignments}, :layout => false
  end
  
  def search
    @assignments = Assignment.search(params[:q])
  end

  # GET /assignments/tag/java
  # GET /assignments/tag/java.xml
  def tag
    tag_list = params[:id].split('+')
    @assignments = Assignment.find_tagged_with(tag_list, :match_all => true)
    @tag = tag_list.join(' + ')
  end

  # GET /assignments/1
  # GET /assignments/1.xml
  def show
    @assignment = Assignment.find(params[:id])
    @activity_items = @assignment.activity_items.sort{|a,b| b.created_at <=> a.created_at}
    @upload_url = ActionController::Base.asset_host + "/assignments/upload/";
    @download_url = ActionController::Base.asset_host + "/assignments/download/";
    # TODO: for now it is an approximation of the rating because we are reusing code
    # from the web and it only has images for complete stars and no partial ones.
    # This should be implemented in the future, maybe?
    rounded_rating = @assignment.rating.round
    @starsHash = {0 => "nostar", 1 => "onestar", 2 => "twostar", 3 => "threestar", 4 => "fourstar", 5 => "fivestar"}
    @ratingsHash = @starsHash.invert
    @how_many_stars = @starsHash.fetch(rounded_rating)
    @ratings_size = @assignment.ratings.size
    logger.info "******************************" + request.protocol + request.host_with_port
  end

  # GET /assignments/new
  # GET /assignments/new.xml
  def new
    @assignment = Assignment.new
  end

  # GET /assignments/1/edit
  def edit
    @assignment = Assignment.find(params[:id])
    #TODO: Make this more dynamic. Specifically, the suffix should be dynamically generated.
    @upload_url = ActionController::Base.asset_host + "/assignments/upload/";
  end

  def edit_field
    @assignment = Assignment.find(params[:id])
        
    # Update_attributes does not work with tag_list,
    # so I had to check for a tag parameter in the call and then
    # do the tagging manually
    if params["name"] != "tags"
      if @assignment.update_attribute(params["name"], params["value"])
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::UpdateAssignmentString)        
        render :partial => "ajaxy_updated_param", :locals => {:value => params["value"]}, :layout => false
      else
        render :partial => "ajaxy_updated_param", :locals => {:value => "!!!failed!!!"}, :layout => false    
      end
    else
      logger.info "*********** VALUE = " + params["value"]
      
      # TODO: get rid of this workaround
      unless params["value"] == "0"
        @assignment.tag_list = params["value"]
      else
        @assignment.tag_list = ""
      end
      
      if @assignment.save
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::TagAssignmentString)        
        render :partial => "editable_linked_tag_list", :locals => { :assignment_id => @assignment.id, :list => @assignment.tag_list, :user_id => @fb_user.id }
      else
        flash[:notice] = 'Could not edit tags!'
        render :partial => "editable_linked_tag_list", :locals => { :assignment_id => @assignment.id, :list => @assignment.tag_list, :user_id => @fb_user.id }
      end
    end
  end

  # POST /assignments
  # POST /assignments.xml
  def create
    @assignment = Assignment.new(params[:assignment])
    @assignment.facebook_user_id = @fb_user.id
    @assignment.published = false
      if @assignment.save
        flash[:notice] = 'Assignment was successfully created.'
        # @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::CreateAssignmentString)
        redirect_to(@assignment)
      else
        render :action => "new"
      end
  end

  # PUT /assignments/1
  # PUT /assignments/1.xml
  def update
    @assignment = Assignment.find(params[:id])
      if @assignment.update_attributes(params[:assignment])
        flash[:notice] = 'Assignment was successfully updated.'
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::UpdateAssignmentString)        
        redirect_to(@assignment)
      else
        render :action => "edit"
      end
  end
  
  def comment
    @assignment = Assignment.find(params["id"])
    @assignment.comments.create(:body => params[:comment][:body].to_s, :facebook_user_id => @fb_user.id)
    flash[:notice] = "Successfully created your comment..."
    #Add item to activity stream
    @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::CommentAssignmentString)    
    
    #If user has opted for notifications, send email
    if @assignment.facebook_user.pref_comment_notify == true
      # FacebookPublisher.send_email(@fb_user.facebooker_user,Array(@assignment.facebook_user.facebooker_user), "Someone commented on your assignment", "someone commented on your assignment at catspace!", "someone commented on your assignment at catspace!")
      # @fb_user.facebooker_session.send_email(@assignment.facebook_user.uid, "someone commented on your assignment", "someone commented on your assignment " + @assignment.title)
    end
    redirect_to :action=>"show", :id => params[:id]
  end
  
  def rate
    a = Assignment.find(params["id"])
    a.add_rating Rating.new (:rating => Integer(params[:rating][:value]))
    flash[:notice] = "Successfully added your rating..."
    redirect_to :action=>"show", :id => params[:id]
  end
  
  def submit_rating
    # TODO: We have to check if a user has already rated an assignment. If so,
    # then, it will readjust the rating if it is different. If the user hasn't 
    # rated, you need to display the avg rating and then when the user rates it
    # show the user rating. 
    
    a = Assignment.find(params[:assignment_id])
    a.add_rating Rating.new (:rating => params[:rating].to_i)
    #flash[:notice] = "Successfully added your rating..."
    # TODO: for now it is an approximation of the rating because we are reusing code
    # from the web and it only has images for complete stars and no partial ones.
    # This should be implemented in the future, maybe?
    rounded_rating = a.rating.round
    @starsHash = {0 => "nostar", 1 => "onestar", 2 => "twostar", 3 => "threestar", 4 => "fourstar", 5 => "fivestar"}
    @how_many_stars = @starsHash.fetch(rounded_rating)
    @ratings_size = a.ratings.size
    render :partial => "five_star_rating", :locals => { :assignment_id => a.id }
  end

  # DELETE /assignments/1
  # DELETE /assignments/1.xml
  def destroy
    @assignment = Assignment.find(params[:id])
    @assignment.destroy
    redirect_to(assignments_url)
  end
  
  def upload
    @assignment = Assignment.find(params[:id])
    logger.debug "[DEBUG] Got request to upload. ID is " + params[:id] + " filename is " + params[:uploaded_file].original_filename
    @assignment.attach_file(params[:uploaded_file])
    ZipWorker.asynch_unzip_file(:id => @assignment.id, :source => @assignment.path_to_attachment, :target => @assignment.path_to_folder)
    #TODO: This should not be set like this. It should instead be based on feedback from the background job.
    @assignment.update_attribute(:queue_flag, true)
    redirect_to "http://apps.facebook.com/"+ENV['FACEBOOKER_RELATIVE_URL_ROOT']+"/assignments/#{@assignment.id}"
        
  end
  
  # TODO: Validation, + regenerate the zip.
  def remove_file
    @assignment = Assignment.find(params[:id])
    @assignment.remove_file(params[:path])
  end
    
  def ishow
    @assignment = Assignment.find(params[:id])
    render :layout => 'iframe'
  end  
  
  #TODO: Later, when the demo hoopla is over, we need to filter out assignments that have not been published from all listings.
  def flick_switch
    @assignment = Assignment.find(params[:id])
      if @assignment.facebook_user.id = @fb_user.id
        @assignment.published = !(@assignment.published)
        if @assignment.save
          if(@assignment.published)
            flash[:notice] = 'The Assignment was successfully published.'
            #TODO: Move from the "created" string to "published" string.
            @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::CreateAssignmentString)        
          else
            flash[:notice] = 'The Assignment was successfully unpublished.'
          end
          redirect_to(@assignment)
        else
          flash[:alert] = 'An error occured while updating the assignment. Please try again.'
          redirect_to(@assignment)
        end
      else
        flash[:alert] = 'You are not the author of that assignment.'
        redirect_to(@assignment)
      end
  end
  
  def authors
    @assignment = Assignment.find(params[:id])
    @authors = @assignment.authorships(:select => "facebook_users_uid")
    if @assignment.facebook_user.id != @fb_user.id
      flash[:alert] = "You need to be the owner of the assignment to edit authors."
      redirect_to @assignment
    end
  end
  
  def add_authors
    user_ids = params[:ids]
    assignment = Assignment.find(params[:id])
  
    if assignment.facebook_user.id == @fb_user.id
      for uid in user_ids
        assignment.authorships.create(:facebook_user_uid => uid, :role => 1)
      end
      flash[:notice] = "Successfully added authors."
    else 
      flash[:alert] = "You need to be the owner of the assignment to add authors."
    end
    
    redirect_to :controller => "assignments", :action => "authors", :id => params[:id]
  end
  
  def remove_author
    assignment = Assignment.find(params[:id])
    authorship = assignment.authorships.find(:first, :conditions => {:facebook_user_uid => params[:uid]})
  
    if assignment.facebook_user.id == @fb_user.id
      authorship.destroy
      flash[:notice] = "Successfully removed author."
    else 
      flash[:alert] = "You need to be the owner of the assignment to remove authors."
    end
    
    redirect_to :controller => "assignments", :action => "authors", :id => params[:id]
  end
  
  def download
    assignment = Assignment.find(params[:id])
    
    if assignment.published
      send_file assignment.path_to_attachment, :type => "application/zip"      
    else
      flash[:alert] = "The Assignment is not published yet."
      redirect_to "http://apps.facebook.com/"+ENV['FACEBOOKER_RELATIVE_URL_ROOT']+"/assignments/#{assignment.id}"
    end

  end
  
  def update_tags
    assignment = Assignment.find(params[:assignment_id])
    render :partial => "update_tags", :locals => {:assignment => assignment}, :layout => false    
  end
  def display_editable_tag_list
    @assignment = Assignment.find(params[:id])
    render :partial => "editable_linked_tag_list", :locals => { :assignment_id => @assignment.id, :list => @assignment.tag_list, :user_id => @fb_user.id }    
  end
  
end
