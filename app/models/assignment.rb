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
  has_many :comments, :dependent => :destroy
  has_many :activity_items, :dependent => :destroy
  has_many :authorships, :dependent => :destroy

  validates_presence_of :title, :on => :create, :message => "can't be blank"

  # Test for author
  def is_author?(user)
    for authorship in self.authorships
      if user.uid == authorship.facebook_user_uid
        return true
      end
    end
    false
  end

  def attach_file(uploaded_file, i = 1)
    # TODO: Destroy anything if its already there. We're assuming that
    # the controller has taken care of verifications.
    # if !self.attachment_name
    #   FileUtils.rm_rf self.path_to_attachment
    #   FileUtils.rm_rf self.path_to_folder
    # end
    # TODO: validate for file type.
    @uploaded_file = uploaded_file

    # If for some reason the attachment name isn't already defined (Shouldn't
    # happen, its defined as <ID>.zip)
    if (!self.attachment_name)
      self.attachment_name = self.id.to_s + ".zip"
      #self.attachment_name = sanitize_filename(@uploaded_file.original_filename)
      #self.attachment_name = self.attachment_name.sub(/^(.*?)(\.[^\.]+)?$/, '\1' + "#{i+=1}" + '\2') while File.exists? (self.path_to_attachment)
      self.save
    end

    # if it's large enough to be a real file
    return FileUtils.copy( @uploaded_file.local_path, self.path_to_attachment(false)) if @uploaded_file.instance_of?(Tempfile)
    # else
    File.open(self.path_to_attachment(false), "w") { |f| f.write(@uploaded_file.read) }
  end

  def path_to_attachment(public = true, filename = self.attachment_name)
    if filename
      if public
        FileSystem.PathToPublicAttachment + filename
      else
        FileSystem.PathToInstructorAttachment + filename
      end
    else
      false
    end
  end

  # Check if a file is publicly visible, or is just for instructors/owner.
  # The file name should be relative to self.path_to_folder
  def is_public?(file)
    return file =~ %r{^([^/]*/)?(solution|software-tests(?!/public))/}
  end

  def path_to_folder
    FileSystem.PathToFolder + self.id.to_s + "/"
  end

  def sanitize_filename(name)
    # get only the filename, not the whole path and
    # replace all none alphanumeric, underscore or periods with underscore
    File.basename(name.gsub('\\', '/')).gsub(/[^\w\.\-]/,'_')
  end

  def before_destroy
    # delete the file from the filesystem
    if self.path_to_attachment(true)
      FileUtils.rm_rf self.path_to_attachment(true)
    end
    if self.path_to_attachment(false)
      FileUtils.rm_rf self.path_to_attachment(false)
    end
    if self.path_to_folder
      FileUtils.rm_rf self.path_to_folder
    end
  end

  def remove_attachment
    # delete the file from the filesystem
    self.remove_zip
    self.update_attributes(:attachment_name => NULL)
  end

  def remove_zip
    # delete the file from the filesystem
    FileUtils.rm_rf self.path_to_attachment(true)
    FileUtils.rm_rf self.path_to_attachment(false)
  end

  # The path parameter is the relative path for the file within the assignment package.
  # It should not be prefixed with a "/". It should be suffixed with a "/". Eg:
  # "sources/simpsons/doh/"
  def add_file(uploaded_file, path)
    filename = sanitize_filename(uploaded_file.original_filename)

    if (path and path != '')
      FileUtils.mkdir_p(self.path_to_folder + path)
    end

    # if it's large enough to be a real file
    return FileUtils.copy(uploaded_file.local_path, self.path_to_folder + path + filename) if uploaded_file.instance_of?(Tempfile)
    # else
    File.open(self.path_to_folder + path + filename, "w") { |f| f.write(uploaded_file.read) }
  end


  def remove_file(path)
    file = File.join(self.path_to_folder, path)
    return FileUtils.rm_rf file
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
        if properties["sameer"]
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

        # Create folder if it doesn't exist
        FileUtils.mkdir_p self.path_to_folder

        file = File.join(self.path_to_folder, "assignment.properties")

        # Touch file to make sure it exists
        FileUtils.touch file

        properties = JavaProperties::Properties.new(file)

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
        # JavaProperties::Properties.write(file, properties, "Properties file for #{self.title}, generated on #{DateTime.now}")
        properties.store(file, "Properties file for #{self.title}, generated on #{DateTime.now}")
    else
      logger.error { "[ERROR] Assignment folder not found. Not writing to the properties file!" }
    end
  end



end
