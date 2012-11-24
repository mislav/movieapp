# Information about ratings of a group of people that watched a movie
WatchesStats = Struct.new(:movie, :user_ids) do
  def watched_collection
    User.collection['watched']
  end

  def query_conditions
    cond = { movie_id: movie.id }
    cond[:user_id] = { '$in' => user_ids } if user_ids.present?
    cond
  end

  def people_who_rated rating
    users_by_rating[rating]
  end

  def present?
    users_by_rating.any? {|k,v| v.present? }
  end

  def users_by_rating
    return @by_rating if defined? @by_rating

    @by_rating = Hash.new {|h,k| h[k] = [] }
    return @by_rating if !user_ids.nil? and user_ids.empty?

    watches = watched_collection.find(
      query_conditions,
      fields: %w[user_id liked],
      sort: [:_id, :desc]
    ).to_a

    watched_user_ids = watches.map {|w| w['user_id'] }
    users_by_id = User.find(watched_user_ids, fields: %w[username name]).index_by(&:id)

    watches.each_with_object(@by_rating) { |watch, map|
      map[watch['liked']] << users_by_id.fetch(watch['user_id'])
    }
  end
end
