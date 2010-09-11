class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :add_to_watch, :add_watched]
  
  def index
    if @query = params[:q]
      @movies = Movie.tmdb_search(@query).paginate(:page => params[:page], :per_page => 30)
    elsif @director = params[:director]
      @movies = Movie.paginate({:directors => @director}, :sort => ['year', :desc], :page => params[:page], :per_page => 10)
    else
      @movies = Movie.paginate(:sort => 'title', :page => params[:page], :per_page => 10)
    end
  end
  
  def show
    @movie.ensure_extended_info unless Movies.offline?
  end
  
  def add_to_watch
    current_user.to_watch << @movie
    redirect_to :back
  end
  
  def add_watched
    current_user.watched.add_with_rating @movie, params[:liked]
    redirect_to :back
  end
  
  def to_watch
    @user = User.first(:username => params[:username])
    @movies = @user.to_watch
  end
  
  protected
  
  def find_movie
    @movie = Movie.first(params[:id])
  end

end
