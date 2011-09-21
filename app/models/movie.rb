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

  collection.ensure_index :tmdb_id

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
  include Permalink
  extend Merge
  extend ActiveSupport::Memoizable

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
  
  # creates Movie instances by first checking for existing records in the db
  class RecordSpawner
    attr_reader :tmdb_ids, :made_movies, :imdb_ids

    def initialize(tmdb_movies)
      @tmdb_movies = tmdb_movies
      @tmdb_ids = @tmdb_movies.map(&:id)
      @made_movies = []
      @imdb_ids = []
    end

    def existing
      @existing ||= Movie.find(:tmdb_id => {'$in' => tmdb_ids}).index_by(&:tmdb_id)
    end

    def find_linked_to_netflix(netflix_title)
      if movie = existing.values.find { |mov| mov.netflix_id == netflix_title.id }
        @tmdb_movies.find { |tmdb| movie.tmdb_id == tmdb.id }
      else
        @tmdb_movies.find { |tmdb| tmdb == netflix_title }
      end
    end

    def make(tmdb_movie, netflix_title = nil)
      return if tmdb_movie.imdb_id.present? and imdb_ids.include? tmdb_movie.imdb_id
      movie = existing[tmdb_movie.id] || Movie.new
      movie.tmdb_movie = tmdb_movie
      movie.netflix_title = netflix_title if netflix_title
      made_movies << movie
      imdb_ids << movie.imdb_id if movie.imdb_id
      movie
    end

    def make_all
      @tmdb_movies.each { |mov| make(mov) }
    end
  end

  def self.from_tmdb_movies(tmdb_movies)
    spawner = RecordSpawner.new(tmdb_movies)
    block_given? ? yield(spawner) : spawner.make_all
    spawner.made_movies
  end

  def self.search(term)
    tmdb_movies = Tmdb.search(term).movies.reject { |m| m.year.blank? }
    netflix_titles = if tmdb_movies.any?
      Netflix.search(term, :expand => %w[synopsis directors]).titles
    else []
    end

    from_tmdb_movies(tmdb_movies) do |spawner|
      netflix_titles.each do |netflix_title|
        if tmdb_movie = spawner.find_linked_to_netflix(netflix_title)
          tmdb_movies.delete(tmdb_movie)
          spawner.make(tmdb_movie, netflix_title)
        end
      end

      tmdb_movies.each { |tmdb| spawner.make(tmdb) }
    end.each(&:save)
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
