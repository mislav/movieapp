require 'netflix'
require 'tmdb'

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

  property :runtime
  # property :language
  property :countries
  property :homepage

  property :directors
  # key :cast, Array
  
  def self.tmdb_search(term)
    from_tmdb_results Tmdb.search(term)
  end
  
  def self.from_tmdb_results(tmdb)
    tmdb.movies.map { |movie| find_or_create_from_tmdb(movie) }
  end
  
  def self.find_or_create_from_tmdb(movie, attributes = nil)
    first(:tmdb_id => movie.id) || new(attributes).tap { |fresh|
      fresh.copy_properties_from_tmdb(movie)
      fresh.save
    }
  end
  
  def copy_properties_from_tmdb(movie)
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
  end
  
  EXTENDED = [:runtime, :countries, :directors, :homepage]
  
  def ensure_extended_info
    if extended_info_missing? and self.tmdb_id
      movie = Tmdb.movie_details(self.tmdb_id)
      copy_properties_from_tmdb(movie)
      self.save
    end
  end
  
  def extended_info_missing?
    EXTENDED.any? { |property| self[property].nil? }
  end
  
  def self.netflix_search(term, options = {})
    catalog = Netflix.search(term, options)
    
    WillPaginate::Collection.create(page, catalog.per_page, catalog.total_entries) do |collection|
      collection.replace catalog.titles.map { |title|
        find_or_create_from_netflix(title)
      }
    end
  end
  
  def self.find_or_create_from_netflix(title)
    first(:netflix_id => title.id) || create(
      :title => title.name,
      :year => title.year,
      :poster_small_url => title.poster_medium,
      :poster_medium_url => title.poster_large,
      :runtime => title.runtime,
      :plot => title.synopsis,
      :directors => title.directors,
      :cast => title.cast,
      :netflix_id => title.id,
      :netflix_url => title.netflix_url,
      :official_website => title.official_url
    )
  end
  
  RomanNumeralsMap = Hash[%w[i ii iii iv v vi vii viii ix xi xii].each_with_index.map { |s,i| [s, i+1] }]
  RomanNumerals = /\b(?:i?[vx]|[vx]?i{1,3})\b/
  
  def self.normalize_title(original, year = nil)
    ActiveSupport::Inflector.transliterate(original).tap do |title|
      title.downcase!
      title.squish!
      title.gsub!(/[^\w\s]/, '')
      title.gsub!(RomanNumerals) { RomanNumeralsMap[$&] }
      title.gsub!(/\b(episode|season|part) one\b/, '\1 1')
      title << " (#{year})" if year
    end
  end
  
  def self.search(term)
    tmdb_result = Tmdb.search(term)
    netflix_result = Netflix.search(term)
    
    [].tap do |movies|
      tmdb_map = tmdb_result.movies.each_with_object(ActiveSupport::OrderedHash.new) { |m, map|
        map[normalize_title(m.name, m.year)] = m
      }
      netflix_map = netflix_result.titles.each_with_object(ActiveSupport::OrderedHash.new) { |m, map|
        map[normalize_title(m.name, m.year)] = m
      }

      netflix_map.each do |title, netflix_title|
        if tmdb_movie = tmdb_map.delete(title)
          movies << find_or_create_from_tmdb(tmdb_movie, :netflix_title => netflix_title)
        end
      end
      
      movies.concat tmdb_map.values.map { |netflix| find_or_create_from_tmdb(netflix) }
    end
  end

end
