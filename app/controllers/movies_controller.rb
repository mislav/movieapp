class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :edit, :update, :destroy]
  
  def index
    @movies = Movie.all :order => 'year ASC'
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
