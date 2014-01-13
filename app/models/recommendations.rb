require 'fickle'
require 'forwardable'

Recommendations = Struct.new(:user) do
  extend Forwardable
  def_delegators :movies, :any?, :empty?, :size

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

  # response: [ [ [id, rating], [id, rating], ... ] ]
  def fetch_recommendations
    Rails.cache.fetch("recommendations/#{user.id}", expires_in: 1.day) do
      fickle = Fickle::Client.new(fickle_url, fickle_key)
      fickle.connection.options[:timeout] = 5
      begin
        fickle.recommend([user.id.to_s], 20)
      rescue Faraday::Error::TimeoutError
        return [[]]
      end
    end
  end

  def fickle_url
    Movies::Application.config.fickle.url
  end

  def fickle_key
    Movies::Application.config.fickle.api_key
  end
end
