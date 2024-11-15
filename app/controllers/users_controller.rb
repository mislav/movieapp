require 'csv'

class UsersController < ApplicationController
  
  before_action :load_user, :only => [:show, :to_watch, :liked, :recommendations]
  before_action :login_required, :only => [:following, :recommendations]
  
  def index
    @users = User.find({}, :sort => ['_id', -1]).to_a

    respond_to do |wants|
      wants.html
      wants.csv do
        render :plain => CSV.generate { |csv|
          csv << %w[_id username]
          @users.each {|u| csv << [u.id, u.username] }
        }
      end
    end
  end

  # db- and memory-heavy
  def watched_index
    col = User.collection['watched']
    watched = col.find.to_a
    movies = Movie.find(watched.map {|w| w['movie_id'] }.uniq, :fields => ['title', 'year']).index_by(&:id)

    respond_to do |wants|
      wants.csv do
        render :plain => CSV.generate { |csv|
          csv << %w[_id user_id liked movie_id movie_title]
          watched.each do |watch|
            movie = movies[watch['movie_id']] or next
            title = movie.original_title || movie.title
            title += " (#{movie.year})" if movie.year
            csv << [
              watch['_id'],
              watch['user_id'],
              watch['liked'].to_s,
              movie.id,
              title
            ]
          end
        }
      end
    end
  end
  
  def show
    respond_to do |format|
      format.html do
        @movies = @user.watched(max_id: params[:max_id]).page(params[:page])
        @recommended = Recommendations.new(@user)
        ajax_pagination if my_page? || stale?(etag: session_cache_key(@movies))
      end
      format.csv do
        # https://letterboxd.com/about/importing-data/
        to_numeric_rating = ->(liked) {
          case liked
          when true then 5.0
          when nil then 3.0
          when false then 1.0
          end
        }
        render :plain => CSV.generate { |csv|
          csv << %w[Title Year tmdbID Rating WatchedDate Tags]
          @user.watched.each do |movie|
            csv << [
              movie.title,
              movie.year,
              movie.tmdb_id,
              to_numeric_rating.(@user.watched.rating_for(movie)),
              @user.watched.rated_date_for(movie).strftime("%Y-%m-%d"),
              "movi.im",
            ]
          end
        }
      end
    end
  end
  
  def liked
    @movies = @user.watched(max_id: params[:max_id]).liked.page(params[:page])
    ajax_pagination if stale? etag: session_cache_key(@movies)
  end
  
  def to_watch
    respond_to do |format|
      format.html do
        @movies = @user.to_watch(max_id: params[:max_id]).page(params[:page])
        @recommended = Recommendations.new(@user)
        ajax_pagination if my_page? || stale?(etag: session_cache_key(@movies))
      end
      format.csv do
        # https://letterboxd.com/about/importing-data/
        render :plain => CSV.generate { |csv|
          csv << %w[Title Year tmdbID]
          @user.to_watch.each do |movie|
            csv << [
              movie.title,
              movie.year,
              movie.tmdb_id,
            ]
          end
        }
      end
    end
  end
  
  def timeline
    # TODO: HTTP caching
    @movies = current_user.movies_from_friends(max_id: params[:max_id])
    ajax_pagination
  end

  def recommendations
    @recommended = Recommendations.new(@user)
    unless Movies.offline?
      @recommended.movies.map(&:ensure_extended_info)
    end
  end

  def following
  end

  def follow
    current_user.add_friend(params[:id])
    redirect_to :back
  end
  
  def unfollow
    current_user.remove_friend(params[:id])
    redirect_to :back
  end

  def compare
    user_names = params[:users].split('+')

    if user_names.size != 2
      render 'shared/error', status: 400, locals: {
        error: "Nice try. You can only compare 2 users at a time."
      }
    else
      users = user_names.map {|name| find_user name }

      if users.all?
        @compare = User::Compare.new(*users)
        fresh_when etag: session_cache_key(@compare)
      else
        user_missing = user_names[users.index(nil)]
        @message = "Could not find user #{user_missing.inspect}."
        render 'shared/not_found', status: 404
      end
    end
  end
  
  protected
  
  def load_user
    @user = find_user(params[:username]) or
      render_not_found(%(A user named "#{params[:username]}" doesn't exist.))
  end

  def find_user(username)
    if logged_in? and username == current_user.username
      current_user
    else
      User.first(:username => username)
    end
  end

  private

  def my_page?
    logged_in? and current_user == @user
  end

end
