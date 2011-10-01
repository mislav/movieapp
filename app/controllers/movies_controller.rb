class MoviesController < ApplicationController
  
  before_filter :find_movie, :except => :index
  admin_actions :only => [:edit, :update, :change_plot_field, :link_to_netflix]
  
  rescue_from 'Net::HTTPExceptions', 'Faraday::Error::ClientError' do |error|
    render 'shared/error', :status => 500, :locals => {:error => error}
  end
  
  def index
    if query = params[:q]
      perform_search query
    elsif @director = params[:director]
      expires_in 30.minutes
      @movies = Movie.find(:directors => @director).sort(:year, :desc).page(params[:page])
      freshness_from_cursor @movies
    else
      expires_in 5.minutes
      if stale?(:last_modified => Movie.last_watch_created_at)
        @movies = Movie.last_watched.to_a
      end
    end

    ajax_pagination
  end

  def perform_search(query)
    @query = query

    if params[:local]
      @movies = Movie.search_regexp(@query, :no_escape).page(params[:page])
    elsif params[:netflix]
      @movies = Netflix.search(@query, :expand => %w'directors').titles
      render :netflix_search, :layout => !request.xhr?
    else
      @movies = Movie.search(@query).paginate(:page => params[:page], :per_page => 30)
      redirect_to movie_url(@movies.first) if @movies.total_entries == 1
    end
  end
  
  def show
    if redirect_to_permalink? @movie
      redirect_to movie_url(@movie.permalink), status: 301
    elsif stale?(:last_modified => @movie.updated_at.utc, :etag => @movie)
      @movie.ensure_extended_info unless Movies.offline?
    end
  end
  
  def edit
    render :layout => !request.xhr?
  end
  
  def update
    @movie.update_and_lock params[:movie]
    @movie.save
    redirect_to movie_url(@movie)
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
  
  def link_to_netflix
    @movie.update_netflix_info(params[:netflix_id])
    redirect_to movie_url(@movie)
  end
  
  def dups
    @duplicate_titles = Movie.find_duplicate_titles
  end
  
  def without_netflix
    @movies = Movie.find_no_netflix.page(params[:page])
    @query = "no Netflix"
    render :index unless request.xhr?
    ajax_pagination
  end
  
  protected
  
  def find_movie
    @movie = Movie.find_by_permalink(params[:id]) or
      render_not_found("This movie couldn't be found.")
  end
  
  private

  def redirect_to_permalink?(movie)
    (movie.permalink.present? and params[:id] != movie.permalink) or
      (movie.no_permalink? and movie.generate_permalink and movie.save)
  end

  def ajax_actions_or_back
    if request.xhr?
      response.content_type = Mime::HTML
      render :partial => 'actions', :locals => {:movie => @movie}
    else
      redirect_to :back
    end
  end

end
