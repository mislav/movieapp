require 'nibble_endpoints'
require 'failsafe_store'
require 'active_support/core_ext/object/blank'
require 'movie_title'

module RottenTomatoes
  extend NibbleEndpoints

  define_connection 'http://api.rottentomatoes.com/api/public/v1.0' do |conn|
    conn.params[:apikey] = Movies::Application.config.rotten_tomatoes.api_key

    if user_agent = Movies::Application.config.user_agent
      conn.headers[:user_agent] = user_agent
    end

    conn.response :json

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'rotten_tomatoes', :expires_in => 1.day,
          :exceptions => ['Faraday::Error::ClientError']
      end
    end

    conn.use :instrumentation
    conn.adapter :net_http
  end

  class Movie < NibblerJSON
    include MovieTitle

    def ==(other)
      if other.is_a?(Movie)
        id == other.id
      elsif imdb_id and other.respond_to? :imdb_id and other.imdb_id
        imdb_id == other.imdb_id
      else
        super
      end
    end

    element :id, :with => lambda {|id| id.to_s }
    element '.title' => :name
    element :year
    elements :genres
    element '.alternate_ids.imdb' => :imdb_id, :with => lambda { |id| "tt#{id}" }
    element '.links.alternate' => :url
    element '.ratings.critics_score' => :critics_score
    element :posters

    POSTER_SIZES = [
      'thumbnail', # 61x91
      'profile',   # 120x178
      'detailed',  # 180x266
      'original'   # 510x755
    ].each { |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def poster_#{name}
          posters && posters["#{name}"]
        end
      RUBY
    }
  end

  endpoint(:search_movies, 'movies.json?q={query}&page_limit={limit}&page={page}') do
    element  :total
    elements :movies, :with => Movie
    element  '.links.next' => :next_url
  end

  def self.search query, options = {}
    get :search_movies, :query => query,
      :page => options.fetch(:page, 1),
      :limit => options.fetch(:limit, 5)
  end

  endpoint(:movie_details, 'movies/{id}.json', Movie)

  def self.movie_details id
    get :movie_details, :id => id
  end

  endpoint(:related_movies, 'movies/{id}/similar.json?limit={limit}') do
    elements :movies, :with => Movie
  end

  def self.related_movies id, options = {}
    get :related_movies, :id => id, :limit => options.fetch(:limit, 5)
  end

  endpoint(:movie_alias, 'movie_alias.json?id={imdb_id}&type=imdb', Movie)

  def self.find_by_imdb_id imdb_id
    movie = get :movie_alias, :imdb_id => '%07d' % imdb_id.to_s.sub('tt', '').to_i
    # TODO: better handling of responses like `{"error":"Could not find a movie with the specified id"}`
    movie if movie.id.present?
  end

end
