require 'netflix'
require 'tmdb'

class Movie < Mingo
  property :title
  
  # key :original_title, String
  # key :year, Integer
  # key :plot, String
  # key :poster_small_url, String
  # key :poster_medium_url, String
  # key :runtime, Integer
  # key :directors, Array
  # key :cast, Array

  # key :official_website, String
  # key :netflix_id, String
  # key :netflix_url, String

  # key :tmdb_id, String
  
  def self.tmdb_search(term)
    result = Tmdb.search(term)
    
    result.movies.map { |movie|
      find_or_create_from_tmdb(movie)
    }
  end
  
  def self.find_or_create_from_tmdb(movie)
    first(:tmdb_id => movie.id) || create(
      :title => movie.name,
      :original_title => movie.original_name,
      :year => movie.year,
      # :poster_small_url => movie.poster_medium,
      # :poster_medium_url => movie.poster_large,
      :plot => movie.synopsis,
      :tmdb_id => movie.id,
      :tmdb_url => movie.url
    )
  end
  
  def self.netflix_search(term, page = 1)
    page ||= 1
    catalog = Netflix.search(term, page)
    
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

end
