require 'nibble_endpoints'
require 'failsafe_store'
require 'active_support/core_ext/object/blank'
require 'movie_title'

module Tmdb
  extend NibbleEndpoints

  define_connection 'http://api.themoviedb.org/3' do |conn|
    if user_agent = Movies::Application.config.user_agent
      conn.headers[:user_agent] = user_agent
    end

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

  default_params do
    { api_key: Movies::Application.config.tmdb.api_key }
  end

  class << self
    attr_accessor :ignore_ids

    private

    def process_movie(movie)
      movie
    end
  end
  self.ignore_ids = []

  class Configuration < NibblerJSON
    element '.images.base_url' => :base_url
    elements '.images.poster_sizes' => :poster_sizes
    
    ORIGINAL_SIZE = 'original'
    
    attr_reader :updated_at
    
    def initialize(*args)
      super
      @updated_at = Time.now
    end
    
    def poster_url(wanted_size, poster_path)
      File.join(base_url, find_size(wanted_size), poster_path)
    end
    
    def find_size(wanted_size)
      wanted_size = wanted_size.to_i
      found = available_sizes.find {|size| size >= wanted_size }
      found ? "w#{found}" : original_size
    end
    
    def available_sizes
      @available_sizes ||= poster_sizes.map {|size| size =~ /^w(\d+)$/ and $1.to_i }.compact.sort
    end
    
    def original_size
      if poster_sizes.include? ORIGINAL_SIZE
        ORIGINAL_SIZE
      else
        raise "no original size available"
      end
    end
    
    def stale?
      updated_at < 1.day.ago
    end
  end
  
  class Cast < NibblerJSON
    elements :crew do
      element :id
      element :job
      element :name
      
      def director?
        job == "Director"
      end
    end
    
    def directors
      crew.select { |member| member.director? }
    end
  end
  
  class Movie < NibblerJSON
    include MovieTitle

    def ==(other)
      other.is_a?(Movie) ? id == other.id : super
    end

    # Distinguishes if the movie representation is from results of search
    # (i.e. with only the most basic fields available).
    def short_form?
      imdb_id.blank? and runtime.blank?
    end

    element :id, :with => lambda { |id| id.to_i }
    element 'title' => :name
    element 'original_title' => :original_name
    element :imdb_id
    element 'overview' => :synopsis, :with => lambda { |text|
      text unless text == "No overview found."
    }
    element :release_date, :with => lambda { |date|
      Date.parse(date) unless date.blank? or date == "1900-01-01"
    }
    element :runtime, :with => lambda { |minutes|
      minutes.to_i unless minutes.to_i.zero?
    }
    # element :language
    elements '.production_countries.name' => :countries
    element :homepage
    element :poster_path

    def original_name=(value)
      @original_name = value == self.name ? nil : value
    end

    attr_accessor :year

    def release_date=(date)
      self.year = date.year if date
      @release_date = date
    end    

    def poster_cover
      if poster_path
        config = Tmdb.configuration
        config.poster_url 185, poster_path
      end
    end
    
    def poster_thumb
      if poster_path
        config = Tmdb.configuration
        config.poster_url 92, poster_path
      end
    end
    
    def directors
      if short_form?
        # movies from results of search don't have directors information available
        []
      else
        cast.directors.map &:name
      end
    end
    
    def cast
      @cast ||= Tmdb.get(:movie_cast, :tmdb_id => id)
    end
    
    def url
      "http://www.themoviedb.org/movie/#{id}"
    end
    
  end

  endpoint(:movie_search, 'search/movie?{-join|&|api_key,query}') do
    elements :results, :with => Movie
    alias_method :movies, :results
  end

  def self.search query
    result = get(:movie_search, :query => query)
    result.movies.map! {|mov| process_movie mov unless ignore_ids.include? mov.id }.compact!
    result
  end

  endpoint(:movie_info, 'movie/{tmdb_id}?api_key={api_key}', Movie)

  def self.movie_details tmdb_id
    movie = get(:movie_info, :tmdb_id => tmdb_id)
    process_movie movie
  end
  
  endpoint(:configuration, 'configuration?api_key={api_key}', Configuration)
  
  def self.configuration
    if defined? @config and @config and !@config.stale?
      @config
    else
      @config = get(:configuration)
    end
  end

  endpoint(:movie_cast, 'movie/{tmdb_id}/casts?api_key={api_key}', Cast)
end

require 'tmdb_ignores'
