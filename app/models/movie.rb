require 'netflix'
require 'tmdb'
require 'rotten_tomatoes'
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
  include LockedValues
  extend Search
  extend Merge

  def normalized_title
    @normalized_title ||= ::MovieTitle::normalize_title(title)
  end

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
    WatchesTimeline.create.limit(20)
  end

  def self.last_watch_created_at
    last_watch = User.collection['watched'].find_one({}, :sort => [:_id, :desc], :fields => :_id)
    last_watch['_id'].generation_time if last_watch
  end

  def self.directors_of_movies(movies)
    movies.map { |m| m['directors'] }.compact.flatten.histogram.to_a.sort_by(&:last).reverse
  end
  
  def tmdb_movie=(movie)
    self.tmdb_id = movie.id
    self.tmdb_url = movie.url
    self.tmdb_version = movie.version
    self.imdb_id = movie.imdb_id.presence

    # renamed properties
    set_unless_locked(:title, movie.name)
    set_unless_locked(:original_title, movie.original_name)
    set_unless_locked(:poster_small_url, movie.poster_thumb)
    set_unless_locked(:poster_medium_url, movie.poster_cover)
    set_unless_locked(:plot, movie.synopsis)

    # same name properties
    [:year, :runtime, :countries, :directors, :homepage].each do |property|
      value = movie.send(property)
      set_unless_locked(property, value) if value.present?
    end
  end
  
  def netflix_title=(netflix)
    self.netflix_id = netflix.id
    self.netflix_url = netflix.url

    set_and_lock(:year, netflix.year) if netflix.year.present? and not locked_value?(:year)
    set_and_lock(:runtime, netflix.runtime) if netflix.runtime.present?

    self.homepage ||= netflix.official_url if netflix.official_url.present?
    self.directors ||= netflix.directors if netflix.directors.present?

    if netflix_plot.blank? and netflix.synopsis.present?
      self.netflix_plot = HTML::FullSanitizer.new.sanitize(netflix.synopsis)
    end
  end

  def rotten_movie=(rotten)
    if rotten
      values = {
        'id'     => rotten.id,
        'genres' => rotten.genres,
        'url'    => rotten.url,
        'critics_score'   => rotten.critics_score,
        'poster_profile'  => rotten.poster_profile,
        'poster_detailed' => rotten.poster_detailed
      }
    else
      values = {}
    end
    values['updated_at'] = Time.now
    self['rotten_tomatoes'] = values
  end

  def rotten_info_stale?
    self['rotten_tomatoes'].nil? or
      self['rotten_tomatoes']['updated_at'] < 1.day.ago
  end

  def rotten_id
    self['rotten_tomatoes'] && self['rotten_tomatoes']['id']
  end

  def rotten_url
    self['rotten_tomatoes'] && self['rotten_tomatoes']['url']
  end

  def critics_score
    if score = self['rotten_tomatoes'] && self['rotten_tomatoes']['critics_score']
      score < 1 ? nil : score
    end
  end

  def update_rotten_movie
    self.rotten_movie = if id = rotten_id
      RottenTomatoes.movie_details(id)
    elsif imdb_id
      RottenTomatoes.find_by_imdb_id(imdb_id)
    end
  end

  EXTENDED = [:runtime, :countries, :directors]
  
  def ensure_extended_info
    if extended_info_missing? and self.tmdb_id
      self.tmdb_movie = Tmdb.movie_details(self.tmdb_id)
      self.save
    end
    if rotten_info_stale?
      update_rotten_movie
      self.save
    end
  rescue Net::HTTPExceptions, Faraday::Error::ClientError, Timeout::Error
    NeverForget.log($!, tmdb_id: self.tmdb_id)
    Rails.logger.warn "An HTTP error occured while trying to get data for TMDB movie #{self.tmdb_id}"
  end
  
  def update_netflix_info(netflix_id = self.netflix_id)
    if netflix_id
      self.netflix_title = Netflix.movie_info(netflix_id)
    else
      self.netflix_id = self.netflix_url = self.netflix_plot = nil
    end
    self.save
  rescue Net::HTTPExceptions, Faraday::Error::ClientError, Timeout::Error
    NeverForget.log($!, netflix_id: self.netflix_id)
    Rails.logger.warn "An HTTP error occured while trying to get data for Netflix movie #{self.netflix_id}"
  end
  
  def extended_info_missing?
    EXTENDED.any? { |property| self[property].nil? }
  end

  def imdb_url
    "http://www.imdb.com/title/#{imdb_id}/" if imdb_id
  end

  WIKIPEDIA_PREFIX = 'http://en.wikipedia.org/wiki/'

  def wikipedia_title=(str)
    super(str.present? ? str.strip.sub(WIKIPEDIA_PREFIX, '') : nil)
  end

  def wikipedia_url
    WIKIPEDIA_PREFIX + wikipedia_title.tr(' ', '_') if wikipedia_title
  end
  
  def get_wikipedia_title
    self.wikipedia_title = Wikipedia.find_title("#{self.title} #{self.year}")
    self.save
    self.wikipedia_title
  end
end
