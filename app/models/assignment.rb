# require '../utility/java_props'
require 'java_properties'
require_dependency "search"

class Assignment < ActiveRecord::Base
  
  acts_as_taggable
  acts_as_rateable
  searches_on :title, :synopsis  
  
  # for will_paginate plugin
  cattr_reader :per_page
  @@per_page = 5
     
  belongs_to :facebook_user, :foreign_key => :facebook_user_id, :class_name => "FacebookUser"
  has_many :comments
  has_many :activity_items 
  has_many :authorships 

  validates_presence_of :title, :on => :create, :message => "can't be blank"
  
  #Test for author
  def is_author?(user)
    for authorship in self.authorships
      if user.uid == authorship.facebook_user_uid
        return true
      end
    end
    false
  end

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
    FileSystem.PathToAttachment + filename
  end
  
  def path_to_folder
    FileSystem.PathToFolder + self.id.to_s + "/"
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
  
  def remove_file(path)
    if ((@assignment.facebook_user.id == @fb_user.id) or (@assignment.is_author? @fb_user))
      file = File.join(self.path_to_folder, path)
      FileUtils.rm_rf file
    end
  end
  
  def read_file(path)
    file = File.new(File.join(self.path_to_folder, path))
    file.read
  end
    
  def write_file(path, content)
    File.open(File.join(self.path_to_folder, path), 'w') {|f| f.write(content) }
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
  
  def read_properties_file
    if self.path_to_folder
      file = File.join(self.path_to_folder, "assignment.properties")
      if File.exists? file
        properties = JavaProperties::Properties.new(file)
        logger.debug { "[DEBUG] " + properties.to_s }
        if properties["sameer"]
          logger.debug {"[DEBUG] "+ properties["sameer"]}
        end

        # remove_column :assignments, :prop_estimated_time
        # remove_column :assignments, :prop_estimated_size
        # remove_column :assignments, :prop_copyright

        #Populate fields
        
        if properties["programming.language"]
          self.prop_language = properties["programming.language"]
        end
        
        if properties["programming.language.version"]
          self.prop_language_version = properties["programming.language.version"]
        end
        
        if properties["license"]
          self.prop_license = properties["license"]
        end
        
        if properties["license.url"]
          self.prop_license_url = properties["license.url"]
        end
        
        if properties["course"]
          self.prop_course = properties["course"]
        end
        
        if properties["info.url"]
          self.prop_info_url = properties["info.url"]
        end

        if properties["estimated.experience"]
          self.prop_estimated_experience = properties["estimated.experience"]
        end

        if properties["estimated.time"]
          self.prop_estimated_time = properties["estimated.time"]
        end

        if properties["estimated.size"]
          self.prop_estimated_size = properties["estimated.size"]
        end

        if properties["copyright"]
          self.prop_copyright = properties["copyright"]
        end
        
        self.save
        
      else
        logger.info { "[INFO] No Properties file found!" }
        false
      end
    end
  end

  def write_properties_file
    if self.path_to_folder
      file = File.join(self.path_to_folder, "assignment.properties")

        properties = Hash.new
        
        logger.debug { "[DEBUG] " + properties.to_s }

        #Populate file hash from fields
        if self.prop_language
          properties["programming.language"] = self.prop_language
        end
        
        if self.prop_language_version
          properties["programming.language.version"] = self.prop_language_version
        end
        
        if self.prop_license
          properties["license"] = self.prop_license
        end
        
        if self.prop_license_url
           properties["license.url"] = self.prop_license_url
        end
        
        if self.prop_course
           properties["course"] = self.prop_course
        end
        
        if self.prop_info_url
           properties["info.url"] = self.prop_info_url
        end

        if self.prop_estimated_experience
           properties["estimated.experience"] = self.prop_estimated_experience
        end

        if self.prop_estimated_time
           properties["estimated.time"] = self.prop_estimated_time
        end

        if self.prop_estimated_size
           properties["estimated.size"] = self.prop_estimated_size
        end

        if self.prop_copyright
           properties["copyright"] = self.prop_copyright
        end
        
        JavaProperties::Properties.write(file, properties, "Properties file for #{self.title}, generated on #{DateTime.now}")        
        
    else
      logger.error { "[ERROR] Assignment folder not found. Not writing to the properties file!" }
    end
  end



end
