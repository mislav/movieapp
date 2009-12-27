class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :edit, :update, :destroy]
  
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
  
  protected
  
    def find_movie
      @movie = Movie.find(params[:id])
    end

end
