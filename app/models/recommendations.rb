require 'forwardable'

Recommendations = Struct.new(:user) do
  extend Forwardable
  def_delegators :movies, :empty?, :size

  def any?
    enabled? && movies.any?
  end

  def load_movies
    Movie.find(recommended_movie_ids)
  end

  def recommended_movie_ids
    @movie_ids ||= Array(fetch_recommendations[0]).map {|item| BSON::ObjectId[item[0]] }
  end

  def movies
    @movies ||= load_movies.reject { |movie|
      ignored_ids.include?(movie.id) ||
        to_watch_ids.include?(movie.id) ||
        watched_ids.include?(movie.id)
    }
  end

  def ignored_ids
    user.ignored_recommendations
  end

  def ignore_movie(movie)
    user.ignored_recommendations << movie.id
  end

  def watched_ids
    @watched ||= user.watched(filter_association).
      link_documents.map {|doc| doc['movie_id'] }
  end

  def to_watch_ids
    @to_watch ||= user.to_watch(filter_association).
      link_documents.map {|doc| doc['movie_id'] }
  end

  def filter_association
    { :movie_id => { '$in' => recommended_movie_ids } }
  end

  def fetch_recommendations
    raise "not implemented"
  end

  def enabled?
    Movies::Application.config.fickle.enabled
  end
end
