class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_action :login_from_token
  
  def self.admin_actions(options)
    before_action :check_admin, options
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

  def login_path(provider)
    "/auth/#{provider}"
  end
  helper_method :login_path

  protected

  def login_from_token
    if session[:user_id].blank? and cookies[:login_token].present?
      unless self.current_user = User.find_by_login_token(cookies[:login_token])
        cookies.delete :login_token
      end
    end
  end

  def check_admin
    unless logged_in? and current_user.admin?
      head :forbidden
    end
  end

  def login_required
    unless logged_in?
      render 'shared/login_required', :status => 401
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
      if next_url = next_movies_url
        response['X-Next-Page'] = next_url
      end
      render :partial => 'movies/movie', :collection => @movies.to_a
    end
  end

  def next_movies_url
    if @movies.respond_to? :has_more?
      url_for max_id: @movies.last_id if @movies.has_more?
    elsif @movies.respond_to? :current_page
      if next_page = @movies.current_page + 1 and next_page <= @movies.total_pages
        url_for page: next_page
      end
    end
  end

  def freshness_from_cursor(cursor)
    fresh_when etag: session_cache_key(cursor.first_selector_id)
  end

  def stale?(params)
    if Movies::Application.config.http_caching
      super
    else
      true
    end
  end

  def session_cache_key(key)
    key = key.cache_key if key.respond_to? :cache_key
    ActiveSupport::Cache.expand_cache_key [key, current_user.try(:id)]
  end
end
