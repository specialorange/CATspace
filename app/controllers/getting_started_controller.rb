class GettingStartedController < ApplicationController
  ensure_authenticated_to_facebook [:except => 'add_facebook_application']
  def setup_facebook_user
    @current_facebook_user  = facebook_session.user
  end
end
