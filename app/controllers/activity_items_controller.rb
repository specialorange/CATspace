class ActivityItemsController < ApplicationController  
  # DELETE /assignments/1
  # DELETE /assignments/1.xml
  def destroy
    item = ActivityItem.find(params[:id])
    item.destroy
    render :partial => "ajaxy_item_deleted", :layout => false
  end
end