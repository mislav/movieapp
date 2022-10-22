require 'nibble_endpoints'
require 'failsafe_store'
require 'movie_title'

module RottenTomatoesPrivate
  extend NibbleEndpoints

  # ${RT.PrivateApiV2FrontendHost}/api/private/v2.0/search/default-list
  # https://www.rottentomatoes.com/api/private/v1.0/movies/12897/recommendations/
  define_connection 'https://www.rottentomatoes.com/api/private/v1.0' do |conn|
    conn.headers[:user_agent] = 'Mozilla/5.0'

    conn.response :json, :content_type => /\bjson$/

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'rotten_tomatoes', :expires_in => 1.day,
          :exceptions => ['Faraday::ServerError']
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

  class MovieFull < Nibbler
    include MovieTitle

    element 'script[type="application/ld+json"]' => :data, :with => -> (json_str) { JSON.parse(json_str) }
    element '#score-details-json' => :score_data, :with => -> (json_str) { JSON.parse(json_str) }

    def critics_score
      @score_data["scoreboard"]["tomatometerScore"]
    end

    def name
      @data["name"]
    end

    def year
      @score_data["scoreboard"]["info"].match(/\b(\d{4,})\b/)[1].to_i
    end

    def genres
      @data["genre"]
    end

    def url
      @data["url"]
    end

    def id
      @data["url"].split("/").last
    end

    def poster_profile
      @data["image"]
    end

    def poster_detailed
      @data["image"]
    end

    def to_hash
      %i[id name year critics_score genres url poster_profile poster_detailed].inject({}) do |h, field|
        h[field] = self.public_send(field)
        h
      end
    end
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

  endpoint(:movie_details, 'https://www.rottentomatoes.com/m/{id}', MovieFull)

  def self.movie_details id
    get :movie_details, :id => id
  end
end
