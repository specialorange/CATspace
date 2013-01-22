class Authorship < ActiveRecord::Base
  
  belongs_to :assignment
  
  def facebook_user
    FacebookUser.find(:first, :conditions => {:uid => self.facebook_user_uid})
  end
  
  
end
