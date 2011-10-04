class UsersController < ApplicationController
  
  before_filter :load_user, :only => [:show, :to_watch, :liked]
  
  def index
    @users = User.find({}, :sort => ['_id', -1]).to_a
  end
  
  def show
    if stale? etag: session_cache_key(@user.watched)
      @movies = @user.watched.reverse.page(params[:page])
      ajax_pagination
    end
  end
  
  def liked
    if stale? etag: session_cache_key(@user.watched)
      @movies = @user.watched.liked.reverse.page(params[:page])
      ajax_pagination
    end
  end
  
  def to_watch
    if stale? etag: session_cache_key(@user.to_watch)
      @movies = @user.to_watch.reverse.page(params[:page])
      ajax_pagination
    end
  end
  
  def following
    # TODO: HTTP caching
    @movies = current_user.movies_from_friends.reverse.page(params[:page])
    ajax_pagination
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
