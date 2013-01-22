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

  def write_properties_file(options)
    logger.debug { "[DEBUG] Writing to property file" }
    assignment = Assignment.find(options[:id]);
    assignment.write_properties_file

  end

   # The options hash needs to have id for the assignment.
   # source is the source folder
   # target is the target zip file
  def zip_file(options)
    
    assignment = Assignment.find(options[:id]);
    logger.debug "[DEBUG] Inside zip_file"
    logger.debug "[DEBUG] Inside zip_file, id of record is " + options[:id].to_s

    source = options[:source]
    target = options[:target]

    source.sub!(%r[/$],'')
    logger.debug "[DEBUG] Inside zip_file, source is :" + source + " and target is: " + target;

    assignment.remove_zip
  
    #Write the zip file.    
    Zip::ZipFile.open(target, 'w') do |zipfile|
          Dir["#{source}/**/**"].each do |file|
            logger.debug { "[DEBUG] zipping file: "+file.to_s }
            zipfile.add(file.sub(source+'/',''),file)
          end
        end

  end  

end