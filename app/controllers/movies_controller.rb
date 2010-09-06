class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :edit, :update, :destroy]
  
  def index
    if @query = params[:q]
      @movies = Movie.tmdb_search(@query)
    else
      @movies = Movie.paginate(:sort => 'title', :page => params[:page], :per_page => 10)
    end
  end
  
  def show
  end
  
  def add_to_watch
    current_user.to_watch << Movie.first(params[:id])
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
