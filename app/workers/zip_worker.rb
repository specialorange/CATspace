# handle asynchronous unzipping.
class ZipWorker < Workling::Base 

  require 'zip/zip'
  require 'zip/zipfilesystem'
   # The options hash needs to have id for the assignment.
  def unzip_file(options)
    
    assignment = Assignment.find(options[:id]);
    logger.debug "[DEBUG] Inside unzip_file"
    logger.debug "[DEBUG] Inside unzip_file, id of record is " + options[:id].to_s

    source = options[:source]
    target = options[:target]

    logger.debug "[DEBUG] Inside unzip_file, source is :" + source + " and target is: " + target;
  
    # Create the target directory.
    # We'll ignore the error scenario where
    begin
      Dir.mkdir(target) unless File.exists? target
    end
  
    Zip::ZipFile::open(source) { 
       |zf| 
       zf.each { |e| 
         fpath = File.join(target, e.name) 
         FileUtils.mkdir_p(File.dirname(fpath)) 
         zf.extract(e, fpath) 
       } 
    }
  
    #If all has gone well, let's read the properties
    assignment.read_properties_file
    
  rescue Zip::ZipDestinationFileExistsError => ex
    # I'm going to ignore this and just overwrite the files.
  
  rescue => ex
    puts ex
  
  end  
end