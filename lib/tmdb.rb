require 'nibble_spec'
require 'failsafe_store'
require 'active_support/core_ext/object/blank'
require 'movie_title'

Nibbler.class_eval do
  def self.rules
    @rules ||= ActiveSupport::OrderedHash.new
  end
end

module Tmdb
  extend NibbleSpec
  
  build_stack 'http://api.themoviedb.org/2.1', :headers => {:user_agent => Movies::Application.config.user_agent}
  
  # instrumentation
  faraday.builder.insert_before Faraday::Adapter::NetHttp, FaradayStack::Instrumentation

  # caching
  if Movies::Application.config.api_caching
    faraday.builder.insert_before FaradayStack::ResponseJSON, FaradayStack::Caching do
      FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'tmdb', :expires_in => 1.day,
        :exceptions => ['Faraday::Error::ClientError']
    end
  end
  
  class ResponseNormalizer < FaradayStack::ResponseMiddleware
    define_parser { |b| Array.new }

    def parse_response?(env)
      body = env[:body]
      body.nil? or body.empty? or body.first == "Nothing found."
    end
  end
  
  faraday.builder.insert_before FaradayStack::ResponseJSON, ResponseNormalizer, :content_type => 'application/json'
  
  class Movie < NibblerJSON
    include MovieTitle
    
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
    element 'posters' => :poster_cover, :with => lambda { |posters|
      poster = posters.find { |p| p["image"]["size"] == "cover" }
      poster.nil? ? '' : poster["image"]["url"]
    }
    element 'posters' => :poster_thumb, :with => lambda { |posters|
      poster = posters.find { |p| p["image"]["size"] == "thumb" }
      poster.nil? ? '' : poster["image"]["url"]
    }    
    element :runtime, :with => lambda { |minutes|
      minutes.to_i unless minutes.to_i.zero?
    }
    # element :language
    element :countries, :with => lambda { |countries|
      countries.map {|c| c["name"]}
    }
    element 'cast' => :directors, :with => lambda { |cast|
      cast.find_all {|c| c["job"] == "Director" }.map{|d| d["name"]}
    }
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
  get(:search_movies, 'Movie.search/en/json/{api_key}/{query}') do
    elements :movies, :with => Movie
  end
  
  def self.search query
    search_movies :api_key => Movies::Application.config.tmdb.api_key, :query => query
  end
  
  # http://api.themoviedb.org/2.1/methods/Movie.getInfo
  get(:get_movie_details, 'Movie.getInfo/en/json/{api_key}/{tmdb_id}') do
    elements :movies, :with => Movie
  end
  
  def self.movie_details tmdb_id
    result = get_movie_details :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => tmdb_id
    result.movies.first
  end
end
