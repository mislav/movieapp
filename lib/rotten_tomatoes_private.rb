require 'nibble_endpoints'
require 'failsafe_store'
require 'movie_title'

module RottenTomatoesPrivate
  extend NibbleEndpoints

  # ${RT.PrivateApiV2FrontendHost}/api/private/v2.0/search/default-list
  # https://www.rottentomatoes.com/api/private/v1.0/movies/12897/recommendations/
  define_connection 'https://www.rottentomatoes.com/api/private/v1.0' do |conn|
    conn.headers[:user_agent] = 'Mozilla/5.0'

    conn.response :json

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'rotten_tomatoes', :expires_in => 1.day,
          :exceptions => ['Faraday::Error::ClientError']
      end
    end

    conn.use :instrumentation
    conn.response :raise_error
    conn.adapter :net_http
  end

  class Movie < NibblerJSON
    include MovieTitle

    element :name
    element :year
    element '.url' => :path
    element '.meterScore' => :critics_score
    element '.posterImage' => :poster_profile

    def poster_detailed() nil end
    alias genres poster_detailed

    def id
      path.split('/').last
    end

    def url
      File.join('//www.rottentomatoes.com/', path)
    end
  end

  class MovieFull < NibblerJSON
    include MovieTitle

    element :id, :with => -> (id) { id.to_s }
    element '.title' => :name
    element :year
    elements '.genreSet.displayName' => :genres
    element '.links.alternate' => :url
    element '.ratings.critics_score' => :critics_score
    element '.posters.profile' => :poster_profile
    element '.posters.detailed' => :poster_detailed
  end

  endpoint(:search_movies, 'search?q={query}&t=movie&page={page}') do
    element '.totalCount' => :total_count
    element '.pageCount' => :total_pages
    elements :movies, :with => Movie
  end

  def self.search query, options = {}
    get :search_movies, :query => query,
      :page => options.fetch(:page, 1)
  end

  endpoint(:movie_details, 'movies/{id}', MovieFull)

  def self.movie_details id
    get :movie_details, :id => id
  end

  endpoint(:related_movies, 'movies/{id}/recommendations/') do
    elements :movies, :with => Movie
  end

  def self.related_movies id
    get :related_movies, :id => id
  end
end
