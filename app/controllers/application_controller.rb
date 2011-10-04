class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :login_from_token, :authentication_denied_notice
  
  def self.admin_actions(options)
    before_filter :check_admin, options
  end
  
  def logged_in?
    !!current_user
  end
  helper_method :logged_in?
  
  def current_user
    self.current_user = User.first(session[:user_id]) if !defined?(@current_user) and session[:user_id]
    @current_user == :false ? nil : @current_user
  end
  helper_method :current_user
  
  def current_user=(user)
    if user
      session[:user_id] = user.id.to_s
      @current_user = user
    else
      session.delete :user_id
      @current_user = :false
      nil
    end
  end
  
  protected

  def login_from_token
    if session[:user_id].blank? and cookies[:login_token].present?
      unless self.current_user = User.find_by_login_token(cookies[:login_token])
        cookies.delete :login_token
      end
    end
  end

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

  def render_not_found(message = nil)
    @message = message
    render 'shared/not_found', :status => 404
  end

  def already_rendered?
    response_body.present?
  end

  def ajax_pagination
    if not already_rendered? and request.xhr?
      render :partial => 'movies/movie', :collection => @movies.to_a
    end
  end

  def freshness_from_cursor(cursor)
    fresh_when etag: session_cache_key(cursor.first_selector_id)
  end

  def session_cache_key(key)
    key = key.cache_key if key.respond_to? :cache_key
    ActiveSupport::Cache.expand_cache_key [key, current_user.try(:id)]
  end
end
