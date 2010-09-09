require 'net/http'
require 'yajl/json_gem'
require 'nibbler/json'
require 'addressable/template'
require 'active_support/core_ext/object/blank'

Nibbler::JsonDocument.class_eval do
  attr_reader :data unless instance_methods.map(&:to_sym).include? :data
end

module Tmdb
  
  # http://api.themoviedb.org/2.1/methods/Movie.search
  SEARCH_URL = Addressable::Template.new 'http://api.themoviedb.org/2.1/Movie.search/en/json/{api_key}/{query}'
  # http://api.themoviedb.org/2.1/methods/Movie.getInfo
  DETAILS_URL = Addressable::Template.new 'http://api.themoviedb.org/2.1/Movie.getInfo/en/json/{api_key}/{tmdb_id}'
  
  def self.search query
    url = SEARCH_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :query => query
    json_string = Net::HTTP.get url
    
    parse json_string
  end
  
  def self.movie_details tmdb_id
    url = DETAILS_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => tmdb_id
    json_string = Net::HTTP.get url
   
    parse(json_string).movies.first
  end
  
  def self.parse json_string
    Result.parse json_string
  end
  
  class Movie < NibblerJSON
    element :id, :with => lambda { |id| id.to_i }
    element :name
    element :original_name
    element :language
    element :imdb_id
    element :url
    element :runtime, :with => lambda { |minutes| minutes.to_i }
    element 'overview' => :synopsis
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
        
        converted.data.clear if converted.data.first == "Nothing found."
      end
    end
  end
  
end
