class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include Twitter::Login::Helpers
  include Facebook::Login::Helpers
  
  before_filter :authentication_denied_notice
  
  def logged_in?
    !!current_user
  end
  helper_method :logged_in?
  
  def current_user
    @current_user ||= twitter_user && User.find_or_create_from_twitter(twitter_user)
  end
  helper_method :current_user
  
  protected
  
  def authentication_denied_notice
    %w[twitter facebook].detect do |service|
      if session[:"#{service}_error"] == 'user_denied'
        session.delete(:"#{service}_error")
        flash.now[:warning] = "You have refused to connect with #{service.titleize}"
      end
    end
  end
end
