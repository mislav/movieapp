class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include Twitter::Login::Helpers
  include Facebook::Login::Helpers
  
  before_filter :authentication_denied_notice
  
  def self.admin_actions(options)
    before_filter :check_admin, options
  end
  
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
  
  def twitter_user?
    !!session[:twitter_user]
  end
  helper_method :twitter_user?
  
  def facebook_user?
    !!session[:facebook_user]
  end
  helper_method :facebook_user?
  
  protected
  
  def authentication_denied_notice
    %w[twitter facebook].detect do |service|
      if session[:"#{service}_error"] == 'user_denied'
        session.delete(:"#{service}_error")
        flash.now[:warning] = "You have refused to connect with #{service.titleize}"
      end
    end
  end
  
  def check_admin
    unless logged_in? and current_user.admin?
      head :forbidden
    end
  end
  
  private
  
  def ajax_pagination
    if request.xhr?
      render :partial => 'movies/movie', :collection => @movies
    end
  end
end
