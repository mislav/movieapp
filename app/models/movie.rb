require 'netflix'
require 'tmdb'

class Movie < Mingo
  property :title
  property :original_title
  property :language
  property :year
  property :plot
  property :poster_small_url
  property :poster_medium_url
  property :runtime
  
  property :tmdb_id
  property :tmdb_url

  # key :directors, Array
  # key :cast, Array

  # key :official_website, String
  # key :netflix_id, String
  # key :netflix_url, String

  # key :tmdb_id, String
  
  def self.tmdb_search(term)
    result = Tmdb.search(term)
    
    if result.class == String then result
    else    
      result.movies.map { |movie|
        find_or_create_from_tmdb(movie)
      }
    end
  end
  
  def self.find_or_create_from_tmdb(movie)
    first(:tmdb_id => movie.id) || create(
      :title => movie.name,
      :original_title => movie.original_name,
      :language => movie.language,
      :year => movie.year,
      :poster_small_url => movie.poster_thumb,
      :poster_medium_url => movie.poster_cover,
      :plot => movie.synopsis,
      :tmdb_id => movie.id,
      :tmdb_url => movie.url
    )
  end
  
  def self.tmdb_details(movie)
    movie.tap do |mingo_movie|
      tmdb_movie = Tmdb.movie_details(mingo_movie.tmdb_id)
      mingo_movie.runtime = tmdb_movie.runtime
      mingo_movie.save
    end
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
