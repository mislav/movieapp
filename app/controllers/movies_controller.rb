class MoviesController < ApplicationController
  
  before_filter :find_movie, :except => :index
  admin_actions :only => :change_plot_field
  
  rescue_from 'Tmdb::APIError', 'Net::HTTPExceptions' do |error|
    render 'shared/error', :status => 500, :locals => {:error => error}
  end
  
  def index
    if @query = params[:q]
      @movies = Movie.search(@query).paginate(:page => params[:page], :per_page => 30)
      redirect_to movie_url(@movies.first) if @movies.size == 1
    elsif @director = params[:director]
      @movies = Movie.find(:directors => @director).paginate(:sort => ['year', :desc], :page => params[:page], :per_page => 10)
    else
      @movies = Movie.last_watched
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
  
  def remove_from_to_watch
    current_user.to_watch.delete @movie
    ajax_actions_or_back
  end
  
  def add_watched
    current_user.watched.rate_movie @movie, params[:liked]
    ajax_actions_or_back
  end
  
  def remove_from_watched
    current_user.watched.delete @movie
    ajax_actions_or_back
  end
  
  def wikipedia
    @movie.get_wikipedia_title unless @movie.wikipedia_title
    redirect_to @movie.wikipedia_url
  end
  
  def change_plot_field
    @movie.toggle_plot_field!
    redirect_to movie_url(@movie)
  end
  
  protected
  
  def find_movie
    @movie = Movie.first(params[:id])
  end
  
  private
  
  def ajax_actions_or_back
    if request.xhr?
      response.content_type = Mime::HTML
      render :partial => 'actions', :locals => {:movie => @movie}
    else
      redirect_to :back
    end
  end

end
