class UsersController < ApplicationController
  
  before_filter :load_user, :only => [:show, :to_watch, :liked]
  before_filter :login_required, :only => [:following]
  
  def index
    @users = User.find({}, :sort => ['_id', -1]).to_a
  end
  
  def show
    @movies = @user.watched(max_id: params[:max_id]).page(params[:page])
    ajax_pagination if stale? etag: session_cache_key(@movies)
  end
  
  def liked
    @movies = @user.watched(max_id: params[:max_id]).liked.page(params[:page])
    ajax_pagination if stale? etag: session_cache_key(@movies)
  end
  
  def to_watch
    @movies = @user.to_watch(max_id: params[:max_id]).page(params[:page])
    ajax_pagination if stale? etag: session_cache_key(@movies)
  end
  
  def timeline
    # TODO: HTTP caching
    @movies = current_user.movies_from_friends(max_id: params[:max_id])
    ajax_pagination
  end

  def following
  end

  def follow
    current_user.add_friend(params[:id])
    redirect_to :back
  end
  
  def unfollow
    current_user.remove_friend(params[:id])
    redirect_to :back
  end

  def compare
    users = params[:users].split('+', 2).map {|name| find_user name }

    @compare = User::Compare.new(*users)
    fresh_when etag: session_cache_key(@compare)
  end
  
  protected
  
  def load_user
    @user = find_user(params[:username]) or
      render_not_found(%(A user named "#{params[:username]}" doesn't exist.))
  end

  def find_user(username)
    if logged_in? and username == current_user.username
      current_user
    else
      User.first(:username => username)
    end
  end

  private

  def my_page?
    logged_in? and current_user == @user
  end

end
