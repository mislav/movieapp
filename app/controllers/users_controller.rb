class UsersController < ApplicationController
  
  before_filter :load_user, :only => [:show, :to_watch, :liked, :friends]
  
  def index
    @users = User.find({}, :sort => ['_id', -1]).to_a
  end
  
  def show
    @movies = @user.watched.reverse.page(params[:page])
    ajax_pagination
  end
  
  def liked
    @movies = @user.watched.liked.reverse.page(params[:page])
    ajax_pagination
  end
  
  def to_watch
    @movies = @user.to_watch.reverse.page(params[:page])
    ajax_pagination
  end
  
  def friends
    @movies = @user.movies_from_friends.reverse.page(params[:page])
    ajax_pagination
  end

  def compare
    users = params[:users].split('+', 2).map {|name| find_user name }
    @compare = User::Compare.new(*users)
  end

  protected
  
  def load_user
    @user = find_user params[:username]
    render :user_not_found, :status => 404 unless @user
  end

  def find_user(username)
    if logged_in? and username == current_user.username
      current_user
    else
      User.first(:username => username)
    end
  end

end
