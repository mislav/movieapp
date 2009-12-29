class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :edit, :update, :destroy, :add_watchlist]
  
  def index
    if @query = params[:q]
      @movies = Movie.netflix_search(@query, params[:page])
    else
      @movies = Movie.paginate(:order => 'title', :page => params[:page], :per_page => 10)
    end
  end
  
  def new
  end
  
  def create
    movie = Movie.create params[:movie]
    redirect_to movie
  end

  def show
  end

  def edit
  end
  
  def update
    @movie.update_attributes params[:movie]
    redirect_to @movie
  end
  
  def destroy
    @movie.destroy
    redirect_to @movies_url
  end
  
  def add_watchlist
    current_user.add_movie_to_watch @movie
    current_user.save!
    redirect_to :back
  end
  
  def watchlist
    @user = User.first(:username => params[:username])
    @movies = @user.movies_to_watch
  end
  
  protected
  
    def find_movie
      @movie = Movie.find(params[:id])
    end

end