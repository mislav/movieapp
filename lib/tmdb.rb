require 'net/http'
require 'yajl/json_gem'
require 'nibbler/json'
require 'addressable/template'
require 'active_support/core_ext/object/blank'
require 'movie_title'
require 'api_cache'

Nibbler.class_eval do
  def self.rules
    @rules ||= ActiveSupport::OrderedHash.new
  end
end

Nibbler::JsonDocument.class_eval do
  attr_reader :data unless instance_methods.map(&:to_sym).include? :data
end

module Tmdb
  
  # http://api.themoviedb.org/2.1/methods/Movie.search
  SEARCH_URL = Addressable::Template.new 'http://api.themoviedb.org/2.1/Movie.search/en/json/{api_key}/{query}'
  # http://api.themoviedb.org/2.1/methods/Movie.getInfo
  DETAILS_URL = Addressable::Template.new 'http://api.themoviedb.org/2.1/Movie.getInfo/en/json/{api_key}/{tmdb_id}'
  
  class APIError < RuntimeError; end
  
  def self.search query
    url = SEARCH_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :query => query
    parse get_json(url)
  end
  
  def self.movie_details tmdb_id
    url = DETAILS_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => tmdb_id
    parse(get_json(url)).movies.first
  end
  
  def self.parse json_string
    Result.parse json_string
  end
  
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
    element 'released' => :year, :with => lambda { |date|
      Date.parse(date).year unless date.blank?
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
  end
  
  class Result < NibblerJSON
    elements :movies, :with => Movie
    
    def self.convert_document(doc)
      super.tap do |converted|
        if Rails.env.development?
          File.open(Rails.root + 'tmp/tmdb-last-request.yml', 'w') { |f|
            f.write YAML.dump(converted)
          }
        end

        # work around stupid API response ["Nothing found."]
        converted.data.clear if converted.data.first == "Nothing found."
      end
    end
  end
  
  class << self
    private
    def get_json(url)
      ApiCache.fetch(:tmdb, url.request_uri) do
        response = Net::HTTP.start(url.host, url.port) { |http|
          http.get url.request_uri, 'user-agent' => 'The movie app <http://movi.im>'
        }
        response.error! unless Net::HTTPSuccess === response
        unless response.content_type.to_s.include? 'json'
          raise APIError, "JSON expected, got: #{response.content_type.inspect}"
        end
        response.body
      end
    end
  end
end
