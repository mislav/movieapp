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
  
  RomanNumeralsMap = Hash[%w[i ii iii iv v vi vii viii ix xi xii].each_with_index.map { |s,i| [s, i+1] }]
  RomanNumerals = /\b(?:i?[vx]|[vx]?i{1,3})\b/
  
  def self.normalize_title(original, year = nil)
    ActiveSupport::Inflector.transliterate(original).tap do |title|
      title.downcase!
      title.gsub!(/[^\w\s]/, '')
      title.squish!
      title.gsub!(RomanNumerals) { RomanNumeralsMap[$&] }
      title.gsub!(/\b(episode|season|part) one\b/, '\1 1')
      title << " (#{year})" if year
    end
  end
  
  def self.search(term)
    tmdb_result = Tmdb.search(term)
    netflix_result = Netflix.search(term, :expand => ['synopsis'])
    
    [].tap do |movies|
      tmdb_map = tmdb_result.movies.ordered_index_by { |mov| normalize_title(mov.name, mov.year) }
      netflix_map = netflix_result.titles.ordered_index_by { |mov| normalize_title(mov.name, mov.year) }

      netflix_map.each do |title, netflix_title|
        if tmdb_movie = tmdb_map.delete(title)
          movies << new(:tmdb_movie => tmdb_movie, :netflix_title => netflix_title)
        end
      end
      
      movies.concat from_tmdb_movies(tmdb_map.values)
      
      movies.each { |m| m.save }
    end
  end

end
