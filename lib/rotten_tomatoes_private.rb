require 'nibble_endpoints'
require 'faraday_middleware'
require 'failsafe_store'
require 'movie_title'

module RottenTomatoesPrivate
  extend NibbleEndpoints

  define_connection 'https://www.rottentomatoes.com' do |conn|
    conn.headers[:user_agent] = 'Mozilla/5.0'

    conn.response :json, :content_type => /\bjson$/

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'rotten_tomatoes-1', :expires_in => 1.day,
          :exceptions => ['Faraday::ServerError']
      end
    end

    conn.response :follow_redirects
    conn.use :instrumentation
    conn.response :raise_error
    conn.adapter :net_http
  end

  class Movie < Nibbler
    include MovieTitle

    element 'a[slot=title]' => :name, :with => -> (el) { el.inner_text.strip }
    element '@releaseyear' => :year #, :with => -> (year) { year.to_i }
    element 'a[slot=title]/@href' => :url
    element '@tomatometerscore' => :critics_score
    element 'img/@src' => :poster_profile

    def poster_detailed() nil end
    alias genres poster_detailed

    def id
      url.split('/').last
    end
  end

  class MovieFull < Nibbler
    include MovieTitle

    element 'script[type="application/ld+json"]' => :data, :with => -> (json_str) { JSON.parse(json_str) }
    element 'score-board/@tomatometerscore' => :critics_score
    element 'score-board [slot=info]' => :year, :with => -> (el) { el.inner_text.match(/\b(\d{4,})\b/)[1].to_i }

    def name
      @data["name"]
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

  endpoint(:search_movies, 'https://www.rottentomatoes.com/search?search={query}') do
    elements 'search-page-result[type=movie] search-page-media-row' => :movies, :with => Movie
  end

  def self.search(query)
    get(:search_movies, :query => query)
  end

  endpoint(:movie_details, 'https://www.rottentomatoes.com/m/{id}', MovieFull)

  def self.movie_details id
    get :movie_details, :id => id
  end
end
