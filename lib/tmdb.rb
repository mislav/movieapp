require 'nibble_endpoints'
require 'failsafe_store'
require 'active_support/core_ext/object/blank'
require 'movie_title'

module Tmdb
  extend NibbleEndpoints

  class ResponseNormalizer < Struct.new(:app)
    def call(env)
      app.call(env).on_complete do
        body = env[:body]
        env[:body] = [] if body.nil? or body.empty? or body.first == "Nothing found."
      end
    end
  end

  define_connection 'http://api.themoviedb.org/2.1' do |conn|
    if user_agent = Movies::Application.config.user_agent
      conn.headers[:user_agent] = user_agent
    end

    conn.use ResponseNormalizer
    conn.response :json

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'tmdb', :expires_in => 1.day,
          :exceptions => ['Faraday::Error::ClientError']
      end
    end

    conn.use :instrumentation
    conn.response :raise_error
    conn.adapter :net_http
  end

  class << self
    attr_accessor :ignore_ids

    private

    def process_movie(movie)
      movie
    end
  end
  self.ignore_ids = []

  class Movie < NibblerJSON
    include MovieTitle

    def ==(other)
      other.is_a?(Movie) ? id == other.id : super
    end

    element :id, :with => lambda { |id| id.to_i }
    element :version, :with => lambda { |num| num.to_i }
    element :name
    element :original_name
    element :imdb_id
    element :url
    element 'overview' => :synopsis, :with => lambda { |text|
      text unless text == "No overview found."
    }
    element 'released' => :release_date, :with => lambda { |date|
      Date.parse(date) unless date.blank? or date == "1900-01-01"
    }
    element '.posters.image[?(@["size"] == "cover")].url' => :poster_cover
    element '.posters.image[?(@["size"] == "thumb")].url' => :poster_thumb
    element :runtime, :with => lambda { |minutes|
      minutes.to_i unless minutes.to_i.zero?
    }
    # element :language
    elements '.countries.name' => :countries
    elements '.cast[?(@["job"] == "Director")].name' => :directors
    element :homepage

    def original_name=(value)
      @original_name = value == self.name ? nil : value
    end

    attr_accessor :year

    def release_date=(date)
      self.year = date.year if date
      @release_date = date
    end
  end

  # http://api.themoviedb.org/2.1/methods/Movie.search
  endpoint(:movie_search, 'Movie.search/en/json/{api_key}/{query}') do
    elements :movies, :with => Movie
  end

  def self.search query
    result = get(:movie_search, :api_key => Movies::Application.config.tmdb.api_key, :query => query)
    result.movies.map! {|mov| process_movie mov unless ignore_ids.include? mov.id }.compact!
    result
  end

  # http://api.themoviedb.org/2.1/methods/Movie.getInfo
  endpoint(:movie_info, 'Movie.getInfo/en/json/{api_key}/{tmdb_id}') do
    elements :movies, :with => Movie
  end

  def self.movie_details tmdb_id
    result = get(:movie_info, :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => tmdb_id)
    process_movie result.movies.first
  end
end

require 'tmdb_ignores'
