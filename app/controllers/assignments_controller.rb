class AssignmentsController < ApplicationController

  # GET /assignments
  # GET /assignments.xml
  # moved sort code to the index because pagination does not work in ajax when using it with facebooker
  def index
    
    sort = params[:sort]
    if sort == 'latest'
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'updated_at DESC'
    elsif sort == 'downloads'
      # TODO download count not available yet
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'UPPER(title) ASC'
    elsif sort == 'rating'
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'rating ASC'
    elsif sort == 'mostRatings'
      @sorted_assignments = (Assignment.paginate :page => params[:page], :conditions => { :published => true }).sort {|a,b| b.ratings.length <=> a.ratings.length}
    elsif sort == 'mostComments'
      @sorted_assignments = (Assignment.paginate :page => params[:page], :conditions => { :published => true }).sort {|a,b| b.comments.length <=> a.comments.length}
    else  
      @sorted_assignments = Assignment.paginate :page => params[:page], :conditions => { :published => true }, :order => 'updated_at DESC'
    end
    # render :partial => "ajaxy_list", :locals => {:assignments => sorted_assignments}, :layout => false
  end

  # List all assignments tagged with the tags specified.
  def tag
    tag_list = params[:id].split('+')
    @assignments = Assignment.find_tagged_with(tag_list, :match_all => true)
    @tag = tag_list.join(' + ')
  end

  def search
    # TODO: search is not filtering unpublished assignments
    @assignments = Assignment.search(params[:q])
  end

  # GET /assignments/1
  # GET /assignments/1.xml
  def show
    @assignment = Assignment.find(params[:id])

    if @assignment.published or @assignment.facebook_user == @fb_user
      @activity_items = @assignment.activity_items.sort{|a,b| b.created_at <=> a.created_at}.first(7)
      @upload_url = ActionController::Base.asset_host + "/assignments/upload/";

      @more_assignments_by_author = Assignment.find(:all, :conditions => {:facebook_user_id => @assignment.facebook_user_id, :published => true}, :limit => 5)
    
      # TODO: for now it is an approximation of the rating because we are reusing code
      # from the web and it only has images for complete stars and no partial ones.
      # This should be implemented in the future, maybe?
      unless @assignment.rated_by_user?(@fb_user) 
        rounded_rating = @assignment.rating.round
      else
        rounded_rating = Rating.find(:first, :conditions => 
                                                  {:user_id => @fb_user.id, :rateable_type => @assignment.class.to_s, :rateable_id => @assignment.id}).rating
      end
      @starsHash = {0 => "nostar", 1 => "onestar", 2 => "twostar", 3 => "threestar", 4 => "fourstar", 5 => "fivestar"}
      @how_many_stars = @starsHash.fetch(rounded_rating)
    else 
      flash[:notice] = 'Sorry! The assignment that you tried to see has been unpublished, please try again later...'
      # TODO: :back didn't work under FB, provide smarter navigation later on
      redirect_to :controller => "home", :action => "index"
    end
    
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
        logger.info "*********** CURRENT ASS PUBLISH STATUS: " + @assignment.published.to_s
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::UpdateAssignmentString) unless not @assignment.published       
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
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::TagAssignmentString) unless not @assignment.published               
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
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::UpdateAssignmentString) unless not @assignment.published        
        redirect_to(@assignment)
      else
        render :action => "edit"
      end
  end
  
  def comment
    @assignment = Assignment.find(params["id"])
    @assignment.comments.create(:body => params[:comment][:body].to_s, :facebook_user_id => @fb_user.id)
    flash[:notice] = "Successfully created your comment."
    #Add item to activity stream
    @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::CommentAssignmentString) unless not @assignment.published             
    
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
    flash[:notice] = "Successfully added your rating."
    redirect_to :action=>"show", :id => params[:id]
  end
  
  def submit_rating
    # TODO: We have to check if a user has already rated an assignment. If so,
    # then, it will readjust the rating if it is different. If the user hasn't 
    # rated, you need to display the avg rating and then when the user rates it
    # show the user rating. 
    
    assignment = Assignment.find(params[:assignment_id])
    new_rating = params[:rating].to_i
    
    unless assignment.rated_by_user?(@fb_user)
      logger.info "****** USER HAS NOT RATED THIS ASSIGNMENT ******* " + assignment.rated_by_user?(@fb_user).to_s
      # TODO: for now it is an approximation of the rating because we are reusing code
      # from the web and it only has images for complete stars and no partial ones.
      # This should be implemented in the future, maybe?
      assignment.add_rating Rating.new (:rating => new_rating, :user_id => @fb_user.id)
    else
      logger.info "****** USER HAS RATED THIS ASSIGNMENT ALREADY **** " + assignment.rated_by_user?(@fb_user).to_s
      current_user_rating = Rating.find(:first, :conditions => {:user_id => @fb_user.id, :rateable_type => assignment.class.to_s, :rateable_id => assignment.id})
      current_user_rating.rating = new_rating
      current_user_rating.save
    end
    
    @starsHash = {0 => "nostar", 1 => "onestar", 2 => "twostar", 3 => "threestar", 4 => "fourstar", 5 => "fivestar"}
    @how_many_stars = @starsHash.fetch(new_rating)
    render :partial => "five_star_rating", :locals => { :assignment_id => assignment.id }
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

  def edit_file
    @assignment = Assignment.find(params[:id])
    if ((@assignment.facebook_user.id == @fb_user.id) or (@assignment.is_author? @fb_user))
      @file_content = @assignment.read_file(params[:path])
    else
      flash[:alert] = "Only authors can edit files within an assignment!"
      redirect_to :back
    end
  end
  
  def read_file
    @assignment = Assignment.find(params[:id])
    @file_content = @assignment.read_file(params[:path])
  end  
  
  def save_file
    @assignment = Assignment.find(params[:id])
    if ((@assignment.facebook_user.id == @fb_user.id) or (@assignment.is_author? @fb_user))
      # logger.debug { "[DEBUG] params[:path] = #{params[:path]} and params[:content] = #{params[:content]}" }
      @assignment.write_file(params[:path], params[:content])
      flash[:notice] = "Successfully saved file #{params[:path]}"
    else
      flash[:alert] = "Only authors can edit files within an assignment!"
    end
    redirect_to @assignment
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
            @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::PublishAssignmentString)             
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
    authorships = assignment.authorships
    
    if assignment.facebook_user.id == @fb_user.id
      for uid in user_ids
        author = Authorship.find(:first, :conditions => {:facebook_user_uid => uid, :assignment_id => assignment.id })
        if !authorships.include? author
          assignment.authorships.create(:facebook_user_uid => uid, :role => 1)
          flash_msg = "Successfully updated authors."
        else
          flash_msg = "Successfully updated authors, however there were some duplicates!"
        end
      end
      flash[:notice] = flash_msg
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
  
  def download_item
    key = Digest::SHA1.hexdigest("--#{DownloadItem::Salt}--#{params[:id]}--#{params[:filepath]}--#{@fb_user.id}--#{DateTime.now}") 
    @download_url = ActionController::Base.asset_host + "/download/?key="+key
    logger.info { "[INFO] The assignment download URL generated is: #{@download_url}" }
    DownloadItem.create(:assignment_id => params[:id], :facebook_user_id => @fb_user.id, :path => params[:filepath],:key => key)
    
    redirect_to @download_url
  end    
  
  def download
    item = DownloadItem.find(:first, :conditions => {:key => params[:key]})
    
    if item
      assignment = Assignment.find(item.assignment_id)
      # TODO: Check if User has the rights to access the assignment. Also check if the assignment actually has files
      send_file assignment.path_to_attachment, :type => "application/zip"
      item.delete
    else
      flash[:alert] = "Could not find the assignment. Please try again"
      redirect_to :back
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
