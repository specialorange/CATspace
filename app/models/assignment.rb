require_dependency "search"

class Assignment < ActiveRecord::Base
  
  acts_as_taggable
  acts_as_rateable
  searches_on :title, :synopsis  
  
  belongs_to :facebook_user, :foreign_key => :facebook_user_id, :class_name => "FacebookUser"
  has_many :comments
  has_many :activity_items  

  validates_presence_of :title, :on => :create, :message => "can't be blank"
  
  def attach_file(uploaded_file, i=1)
    # TODO: Destroy anything if its already there. We're assuming that controller has taken care of verifications.
    # if !self.attachment_name
    #   FileUtils.rm_rf self.path_to_attachment
    #   FileUtils.rm_rf self.path_to_folder   
    # end
    # TODO: validate for file type.
    @uploaded_file = uploaded_file
    fn=self.attachment_name=sanitize_filename(@uploaded_file.original_filename)
    #  self.filename=fn+(i+=1).to_s while File.exists? (self.path_to_file)
    self.attachment_name = self.attachment_name.sub(/^(.*?)(\.[^\.]+)?$/,'\1'+"#{i+=1}"+'\2') while File.exists? (self.path_to_attachment)
    
    #TODO: Need a check here
    self.save
    
    # if it's large enough to be a real file
    return FileUtils.copy( @uploaded_file.local_path, self.path_to_attachment) if @uploaded_file.instance_of?(Tempfile)
    # else
    File.open(self.path_to_attachment, "w") { |f| f.write(@uploaded_file.read) }
  end

  def path_to_attachment(filename = self.attachment_name)
    #TODO: These should rather be picked from some config variable
    RAILS_ROOT + "/data/zips/" + filename
  end
  
  def path_to_folder
    #TODO: These should rather be picked from some config variable
    RAILS_ROOT + "/data/folders/" + self.id.to_s + "/"
  end

  def rename(new_name, old_path=self.path_to_attachment)
    File.rename old_path, self.path_to_attachment(sanitize_filename(new_name)) if self.update_attributes( :attachment_name => sanitize_filename(new_name))
  end

  def sanitize_filename(name)
    # get only the filename, not the whole path and
    # replace all none alphanumeric, underscore or periods with underscore
    File.basename(name.gsub('\\', '/')).gsub(/[^\w\.\-]/,'_') 
  end
  
  def before_destroy
    # delete the file from the filesystem
    FileUtils.rm_rf self.path_to_attachment
    FileUtils.rm_rf self.path_to_folder
  end
  
  def remove_attachment
    # delete the file from the filesystem
    FileUtils.rm_rf self.path_to_attachment
    FileUtils.rm_rf self.path_to_folder
    self.update_attributes(:attachment_name => NULL)
  end
  
  def files(relative = true)
    file_filter = File.join(path_to_folder,"**","*")
    list = Dir.glob(file_filter)
    if (!relative)
      return list
    else
      list.each{ |file| file.slice!(path_to_folder)}
      return list
    end
  end
end
