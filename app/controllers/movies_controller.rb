class MoviesController < ApplicationController
  
  before_filter :find_movie, :except => :index
  admin_actions :only => [:edit, :update, :change_plot_field, :link_to_netflix]
  
  rescue_from 'Net::HTTPExceptions', 'Faraday::Error::ClientError' do |error|
    render 'shared/error', :status => 500, :locals => {:error => error}
  end
  
  def index
    if query = params[:q]
      if query.present?
        perform_search query
      else
        render 'shared/error', :status => 500, :locals => {
          error: "You can't enter a blank query; please search for something."
        }
      end
    elsif @director = params[:director]
      @movies = Movie.find(:directors => @director).sort(:year, :desc).page(params[:page])
      freshness_from_cursor @movies
    else
      if logged_in? or stale?(last_modified: Movie.last_watch_created_at, public: true)
        @movies = Movie.last_watched
      end
    end

    ajax_pagination
  end

  def perform_search(query)
    @query = query

    if params[:local]
      @movies = Movie.search_regexp(@query, :no_escape).page(params[:page])
    elsif params[:netflix]
      require 'netflix'
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
    elsif stale? etag: session_cache_key(@movie)
      @movie.ensure_extended_info unless Movies.offline?

      if @movie.invalid?
        @message = "This movie is now unavailable."
        render 'shared/not_found', :status => 410
      end
    end
  end
  
  def edit
    render :layout => !request.xhr?
  end

  def pick_poster
    @posters = PosterFinder.call @movie

    response.content_type = Mime::HTML
    render :layout => !request.xhr?
  end

  def raw
    @data = case params[:kind]
    when 'tmdb'
      resp = Tmdb.get_raw(:movie_info, tmdb_id: @movie.tmdb_id)
      resp.body
    else
      render text: "Unsupported kind.", status: 400
    end
  end
  
  def update
    @movie.update_and_lock params[:movie]
    @movie.save

    if request.xhr?
      head :ok
    else
      redirect_to movie_url(@movie)
    end
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
    @movie.update_wikipedia_url! unless @movie.wikipedia_url.present?

    if @movie.wikipedia_url.present?
      redirect_to @movie.wikipedia_url, status: 301
    else
      @message = "Can't find this movie on Wikipedia."
      render 'shared/not_found', :status => 404
    end
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
