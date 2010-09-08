class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :edit, :update, :destroy]
  
  def index
    
    if @query = params[:q]
      @result = Movie.tmdb_search(@query)
      
      if (@result.class == String) then @result
      else @movies = @result.paginate(:page => params[:page], :per_page => 5)
      end
      
    else
      @movies = Movie.paginate(:sort => 'title', :page => params[:page], :per_page => 10)
    end
    
  end
  
  def show
    @movie = Movie.tmdb_details(@movie)
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
