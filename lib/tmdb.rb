require 'net/http'
require 'cgi'
require 'uri'
require 'yajl/json_gem'
require 'nibbler/json'

module Tmdb
  # http://api.themoviedb.org/2.1/methods/Movie.search
  def self.search term
    uri = URI.parse("http://api.themoviedb.org/2.1/Movie.search/en/json/#{$settings.tmdb.api_key}/#{CGI.escape term}")
    json_string = Net::HTTP.get(uri)
    parse json_string
  end
  
  def self.parse json_string
    Result.parse json_string
  end
  
  class Movie < NibblerJSON
    element :id, :with => lambda { |id| id.to_i }
    element :name
    element :alternative_name
    element :original_name
    element :imdb_id
    element :url
    element 'overview' => :synopsis
    element 'released' => :year, :with => lambda { |date|
      Date.parse(date).year unless date.blank?
    }
  end
  
  class Result < NibblerJSON
    elements :movies, :with => Movie
  end
  
end
