class AssignmentsController < ApplicationController

  # GET /assignments
  # GET /assignments.xml
  def index
    @assignments = Assignment.find(:all)
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
    if @assignment.update_attribute(params["name"], params["value"])
      @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::UpdateAssignmentString)        
      render :partial => "ajaxy_updated_param", :locals => {:value => params["value"]}, :layout => false
    else
      render :partial => "ajaxy_updated_param", :locals => {:value => "!!!failed!!!"}, :layout => false    
    end
  end

  # POST /assignments
  # POST /assignments.xml
  def create
    @assignment = Assignment.new(params[:assignment])
    @assignment.facebook_user_id = @fb_user.id

      if @assignment.save
        flash[:notice] = 'Assignment was successfully created.'
        @fb_user.activity_items.create(:assignment_id => @assignment.id, :sentence => ActivityItem::CreateAssignmentString)
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
    # TODO: Move to a global var. in environment - Please! OR Use the vars that facebooker is using.
    redirect_to "http://apps.facebook.com/catspace_sa/assignments/#{@assignment.id}"
        
  end
  
  def ishow
    @assignment = Assignment.find(params[:id])
    render :layout => 'iframe'
  end  
end
