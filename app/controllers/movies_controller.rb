class MoviesController < ApplicationController
  
  before_filter :find_movie, :only => [:show, :add_to_watch, :add_watched]
  
  def index
    if @query = params[:q]
      @movies = Movie.search(@query).paginate(:page => params[:page], :per_page => 30)
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
  
  protected
  
  def find_movie
    @movie = Movie.first(params[:id])
  end
  
  private
  
  def ajax_actions_or_back
    if request.xhr?
      render :partial => 'actions', :locals => {:movie => @movie}
    else
      redirect_to :back
    end
  end

end
