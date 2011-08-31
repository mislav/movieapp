class SessionsController < ApplicationController

  include Twitter::Login::Helpers
  include Facebook::Login::Helpers

  skip_before_filter :login_from_token

  # for offline testing purposes only
  def instant_login
    user = Rails.configuration.twitter.test_user
    session[:twitter_user] = user
    signup_user
    redirect_to watched_path(current_user)
  end
  
  def finalize
    signup_user
      
    unless Movies.offline?
      current_user.fetch_twitter_info(twitter_client) if twitter_user
      current_user.fetch_facebook_info(facebook_client) if facebook_user
    end
    
    redirect_to watched_url(current_user)
  end

  def logout
    twitter_logout
    facebook_logout

    if logged_in? and cookies[:login_token].present?
      current_user.delete_login_token cookies[:login_token]
      cookies.delete :login_token
    end
    self.current_user = nil

    redirect_to root_path
  end
  
  private
  
  def signup_user
    if self.current_user = User.login_from_twitter_or_facebook(twitter_user, facebook_user)
      if cookies[:login_token].blank? or !current_user.has_login_token?(cookies[:login_token])
        cookies.permanent[:login_token] = current_user.generate_login_token
      end
    end
  end

end
