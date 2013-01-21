class HomeController < ApplicationController
  def index
    @activity_items = ActivityItem.find(:all, :order => "created_at DESC", :limit => 10)
  end  
end