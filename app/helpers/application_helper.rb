# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include TagsHelper
  
  # def current_user
  #  session[:current_user]
  # end
  def tab_items
   LessonOutline.outline.sections.collect do |section|

   end.join("\n")
  end

  def action_selected?(controller_name, action_name)
   params[:controller].to_s == controller_name.to_s and params[:action].to_s == action_name.to_s
  end   
  
  def self_profile_selected?
   params[:controller].to_s == "facebook_users" and params[:action].to_s == "profile" and (!params[:id])
  end
  
  def people_selected?
    params[:controller].to_s == "facebook_users" and params[:action].to_s == "index"
  end
  
  #Low-def version to highlight a tab only if the controller matches
  def controller_selected?(controller_name)
   params[:controller].to_s == controller_name.to_s
  end   
  
  def iframe_url(suffix)
    ActionController::Base.asset_host+"/"+suffix
  end

  def ajax_on?
   session[:ajaxy]
  end
  
  # For links within content rendered by AJAX calls, eg: canvas("/assignments")
  def canvas(suffix)
    "http://apps.facebook.com/" + ENV['FACEBOOKER_RELATIVE_URL_ROOT'] + suffix
  end
  
  CreateAssignmentString = "created assignment "
  UpdateAssignmentString = "updated assignment "
  CommentAssignmentString = "commented on assignment "

  def activity_icon(item)
    if item.sentence == ActivityItem::CreateAssignmentString
      return "activity_icons/create.png"
    elsif item.sentence == ActivityItem::UpdateAssignmentString
      return "activity_icons/update.png"
    elsif item.sentence == ActivityItem::CommentAssignmentString
      return "activity_icons/comment.png"
    else
      return "activity_icons/unknown.png"
    end
  end
  
end
