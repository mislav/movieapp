module Movie::Search
  # Searches for movies from TMDB using Netflix to help rank results better.
  # If TMDB search fails, uses just Netflix to find existing movies in the db.
  #
  # If all external searches fail, use regular expressions to search existing titles.
  def search(term)
    search_combined(term)
  rescue Faraday::ServerError, Faraday::ParsingError, Timeout::Error
    NeverForget.log($!, term: term)
    search_regexp(term)
  end

  def search_regexp(term, no_escape = false)
    term = Regexp.escape(term) unless no_escape
    query = /\b#{term}\b/i
    find({title: query}, sort: :title)
  end

  def from_tmdb_movies(tmdb_movies)
    spawner = RecordSpawner.new(tmdb_movies)
    block_given? ? yield(spawner) : spawner.make_all
    spawner.made_movies
  end

  private

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

  def search_rotten_tomatoes(term)
    RottenTomatoesPrivate.search(term).movies
  rescue Faraday::ServerError, Timeout::Error
    # we can survive without Rotten results
    NeverForget.log($!, term: term)
    []
  end

  def search_combined(term)
    tmdb_movies = Tmdb.search(term).movies.reject { |m| m.year.blank? }
    return tmdb_movies if tmdb_movies.empty?
    rotten_movies = search_rotten_tomatoes(term)

    from_tmdb_movies(tmdb_movies) do |spawner|
      tmdb_movies.each { |tmdb| spawner.make(tmdb) }
    end.each { |movie|
      if rotten = rotten_movies.delete(movie)
        movie.rotten_movie = rotten
      end
      movie.save
    }
  end
end
