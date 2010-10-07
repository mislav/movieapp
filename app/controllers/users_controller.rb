class UsersController < ApplicationController
  
  before_filter :find_user, :only => [:show, :to_watch, :liked, :friends]
  
  def index
    @users = User.find({}, :sort => ['_id', -1]).to_a
  end
  
  def show
    @movies = @user.watched.paginate(:page => params[:page], :per_page => 10)
    ajax_pagination
  end
  
  def liked
    @movies = @user.watched.liked.paginate(:page => params[:page], :per_page => 10)
    ajax_pagination
  end
  
  def to_watch
    @movies = @user.to_watch.paginate(:page => params[:page], :per_page => 10)
    ajax_pagination
  end
  
  def friends
    @movies = @user.movies_from_friends(:page => params[:page], :per_page => 10)
    ajax_pagination
  end
  
  protected
  
  def find_user
    @user = if logged_in? and params[:username] == current_user.username
      current_user
    else
      User.first(:username => params[:username])
    end
    
    render :user_not_found, :status => 404 unless @user
  end

end
