require 'netflix'
require 'tmdb'
require 'html/sanitizer'

class Movie < Mingo
  property :title
  property :original_title
  property :year
  property :plot
  property :poster_small_url
  property :poster_medium_url
  
  property :tmdb_id
  property :tmdb_url
  property :tmdb_version

  property :netflix_id
  property :netflix_url
  property :netflix_plot

  property :imdb_id

  property :runtime
  # property :language
  property :countries
  property :homepage

  property :directors
  # key :cast, Array
  
  def self.from_tmdb_movies(movies)
    movies.map { |movie| new(:tmdb_movie => movie) }
  end

  # TODO: make this not hit Mongo N times for N records
  def self.new(attributes = nil)
    existing = if attributes and attributes[:tmdb_movie]
      first(:tmdb_id => attributes[:tmdb_movie].id)
    end
    
    if existing
      attributes.each do |property, value|
        existing.send(:"#{property}=", value)
      end
      existing
    else
      super
    end
  end
  
  def tmdb_movie=(movie)
    # renamed properties
    self.title = movie.name
    self.original_title = movie.original_name
    self.poster_small_url = movie.poster_thumb
    self.poster_medium_url = movie.poster_cover
    self.plot = movie.synopsis
    self.tmdb_id = movie.id
    self.tmdb_url = movie.url
    self.tmdb_version = movie.version
    self.imdb_id = movie.imdb_id
    
    # same name properties
    [:year, :runtime, :countries, :directors, :homepage].each do |property|
      value = movie.send(property)
      self.send(:"#{property}=", value) if value.present?
    end
  end
  
  def netflix_title=(netflix)
    self.netflix_id = netflix.id
    self.netflix_url = netflix.url
    self.runtime ||= netflix.runtime
    if netflix.synopsis.present?
      # TODO: optimize this so it's skipped if already done
      self.netflix_plot = HTML::FullSanitizer.new.sanitize(netflix.synopsis)
    end
  end
  
  EXTENDED = [:runtime, :countries, :directors]
  
  def ensure_extended_info
    if extended_info_missing? and self.tmdb_id
      self.tmdb_movie = Tmdb.movie_details(self.tmdb_id)
      self.save
    end
  end
  
  def extended_info_missing?
    EXTENDED.any? { |property| self[property].nil? }
  end
  
  def self.search(term)
    tmdb_movies = Tmdb.search(term).movies
    netflix_titles = Netflix.search(term, :expand => ['synopsis']).titles
    
    [].tap do |movies|
      netflix_titles.each do |netflix_title|
        if tmdb_movie = tmdb_movies.find { |m| m == netflix_title }
          tmdb_movies.delete(tmdb_movie)
          movies << new(:tmdb_movie => tmdb_movie, :netflix_title => netflix_title)
        end
      end
      
      movies.concat(from_tmdb_movies(tmdb_movies)).each(&:save)
    end
  end

  def imdb_url
    "http://www.imdb.com/title/#{imdb_id}/" if imdb_id
  end

end
