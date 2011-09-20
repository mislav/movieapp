require 'netflix'
require 'tmdb'
require 'wikipedia'
require 'html/sanitizer'
require 'movie_title'

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
  property :wikipedia_title

  property :runtime
  # property :language
  property :countries
  property :homepage

  property :directors
  # key :cast, Array
  
  include Mingo::Timestamps
  extend Merge
  extend ActiveSupport::Memoizable

  def to_param
    self.id.to_s
  end

  def normalized_title
    ::MovieTitle::normalize_title(title)
  end
  memoize :normalized_title

  # warning: db-heavy
  def self.find_duplicate_titles
    hash = Hash.new { |h,k| h[k] = [] }
    fields = %w[ title original_title year poster_small_url ]
    find(ids_of_relevant_titles, fields: fields, sort: '$natural').each_with_object(hash) { |movie, map|
      map[movie.normalized_title] << movie
    }.reject { |_, movies| movies.size < 2 }
  end

  def self.find_no_netflix
    fields = %w[ title original_title year poster_small_url ]
    find({_id: {'$in' => ids_of_relevant_titles}, netflix_id: {'$exists' => false}}, fields: fields, sort: :_id)
  end

  # all movies that someone watched or wants to watch
  def self.ids_of_relevant_titles
    ids = User.collection['watched'].find({}, fields: :movie_id).map { |doc| doc['movie_id'] }
    ids.concat User.collection['to_watch'].find({}, fields: :movie_id).map { |doc| doc['movie_id'] }
    ids.uniq
  end

  property :chosen_plot_field

  def chosen_plot
    send(chosen_plot_field || 'plot')
  end

  def customizable_plot?
    netflix_plot.present?
  end

  def toggle_plot_field!
    self.chosen_plot_field = chosen_plot_field == 'netflix_plot' ? 'plot' : 'netflix_plot'
    save
  end

  def next_plot_source
    chosen_plot_field == 'netflix_plot' ? 'TMDB' : 'Netflix'
  end

  def self.last_watched
    watches = User.collection['watched'].find({}, :sort => [:_id, :desc]).limit(20)
    movie_ids = watches.map { |w| w['movie_id'] }.uniq.first(10)
    find(movie_ids)
  end

  def self.last_watch_created_at
    last_watch = User.collection['watched'].find_one({}, :sort => [:_id, :desc], :fields => :_id)
    last_watch['_id'].generation_time if last_watch
  end

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

  def self.directors_of_movies(movies)
    movies.map { |m| m['directors'] }.compact.flatten.histogram.to_a.sort_by(&:last).reverse
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
    self.imdb_id = movie.imdb_id.presence
    
    # same name properties
    [:year, :runtime, :countries, :directors, :homepage].each do |property|
      value = movie.send(property)
      self.send(:"#{property}=", value) if value.present?
    end
  end
  
  def netflix_title=(netflix)
    self.netflix_id = netflix.id
    self.netflix_url = netflix.url

    self.runtime = netflix.runtime if netflix.runtime.present?
    self.homepage = netflix.official_url if netflix.official_url.present?
    self.directors = netflix.directors if netflix.directors.present?
    
    if netflix_plot.blank? and netflix.synopsis.present?
      self.netflix_plot = HTML::FullSanitizer.new.sanitize(netflix.synopsis)
    end
  end
  
  EXTENDED = [:runtime, :countries, :directors]
  
  def ensure_extended_info
    if extended_info_missing? and self.tmdb_id
      self.tmdb_movie = Tmdb.movie_details(self.tmdb_id)
      self.save
    end
  rescue Net::HTTPExceptions, Faraday::Error::ClientError
    Rails.logger.warn "An HTTP error occured while trying to get data for Tmdb movie #{self.tmdb_id}"
  end
  
  def update_netflix_info(netflix_id = self.netflix_id)
    self.netflix_title = Netflix.movie_info(netflix_id)
    self.save
  rescue Net::HTTPExceptions, Faraday::Error::ClientError
    Rails.logger.warn "An HTTP error occured while trying to get data for Tmdb movie #{self.tmdb_id}"
  end
  
  def extended_info_missing?
    EXTENDED.any? { |property| self[property].nil? }
  end
  
  # filters out duplicate TMDB results by "imdb_id"
  class IMDBUniqueFilter
    def initialize
      @imdb_ids = []
    end
    
    def register(movie)
      if movie.imdb_id.blank? or not registered? movie
        yield movie
        @imdb_ids << movie.imdb_id if movie.imdb_id.present?
      end
    end
    
    def registered?(movie)
      @imdb_ids.include? movie.imdb_id
    end
    
    def process(movies)
      movies.each_with_object([]) do |movie, all|
        register(movie) { all << movie }
      end
    end
  end
  
  def self.search(term)
    tmdb_movies = Tmdb.search(term).movies.reject { |m| m.year.blank? }
    netflix_titles = Netflix.search(term, :expand => %w[synopsis directors]).titles
    filter = IMDBUniqueFilter.new
    
    [].tap do |movies|
      netflix_titles.each do |netflix_title|
        if tmdb_movie = tmdb_movies.find { |m| m == netflix_title }
          tmdb_movies.delete(tmdb_movie)
          filter.register(tmdb_movie) do
            movies << new(:tmdb_movie => tmdb_movie, :netflix_title => netflix_title)
          end
        end
      end
      
      other_movies = from_tmdb_movies filter.process(tmdb_movies)
      movies.concat(other_movies).each(&:save)
    end
  end

  def imdb_url
    "http://www.imdb.com/title/#{imdb_id}/" if imdb_id
  end
  
  def wikipedia_url
    'http://en.wikipedia.org/wiki/' + wikipedia_title.tr(' ', '_') if wikipedia_title
  end
  
  def get_wikipedia_title
    self.wikipedia_title = Wikipedia.find_title("#{self.title} #{self.year}")
    self.save
    self.wikipedia_title
  end
end
