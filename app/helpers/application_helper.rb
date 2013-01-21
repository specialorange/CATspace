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
  
  #Low-def version to highlight a tab only if the controller matches
  def controller_selected?(controller_name)
   params[:controller].to_s == controller_name.to_s
  end   
  

  def ajax_on?
   session[:ajaxy]
  end

end
