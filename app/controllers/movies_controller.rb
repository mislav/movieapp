class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :add_to_watch, :add_watched]
  before_filter :find_user, :only => [:watched, :to_watch, :liked, :friends]
  
  def index
    if @query = params[:q]
      @movies = Movie.tmdb_search(@query).paginate(:page => params[:page], :per_page => 30)
    elsif @director = params[:director]
      @movies = Movie.find(:directors => @director).paginate(:sort => ['year', :desc], :page => params[:page], :per_page => 10)
    else
      # TODO: decide what to display on the home page
      @movies = Movie.paginate(:sort => 'title', :page => params[:page], :per_page => 10)
    end
    
    ajax_pagination
  end
  
  def show
    @movie.ensure_extended_info unless Movies.offline?
  end
  
  def add_to_watch
    current_user.to_watch << @movie
    ajax_actions_or_back
  end
  
  def add_watched
    current_user.watched.add_with_rating @movie, params[:liked]
    ajax_actions_or_back
  end
  
  def watched
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
    @movies = @user.movies_from_friends.paginate(:page => params[:page], :per_page => 10)
    ajax_pagination
  end
  
  protected
  
  def find_movie
    @movie = Movie.first(params[:id])
  end
  
  def find_user
    @user = if logged_in? and params[:username] == current_user.username
      current_user
    else
      User.first(:username => params[:username])
    end
  end
  
  private
  
  def ajax_actions_or_back
    if request.xhr?
      render :partial => 'actions', :locals => {:movie => @movie}
    else
      redirect_to :back
    end
  end
  
  def ajax_pagination
    if request.xhr?
      render :partial => 'movie', :collection => @movies
    end
  end

end
