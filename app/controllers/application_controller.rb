class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include Twitter::Login::Helpers
  
  def logged_in?
    !!current_user
  end
  helper_method :logged_in?
  
  def current_user
    @current_user ||= twitter_user && User.find_or_create_from_twitter(twitter_user)
  end
  helper_method :current_user
end
