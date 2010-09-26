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
    self.current_user = User.find_from_twitter_or_facebook(twitter_user, facebook_user) unless @current_user
    @current_user == :false ? nil : @current_user
  end
  helper_method :current_user
  
  def current_user=(user)
    @current_user = user || :false
  end
  
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
