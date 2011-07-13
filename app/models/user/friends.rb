module User::Friends
  def twitter_friends=(ids)
    self['twitter_friends'] = ids.map { |id| id.to_i }
  end

  def facebook_friends=(ids)
    self['facebook_friends'] = ids.map { |id| id.to_s }
  end

  def friends(query = {}, options = {})
    query = {:_id => {"$in" => query}} if Array === query
    query = query.merge('$or' => [
      { 'twitter.id' => {'$in' => Array(self['twitter_friends'])} },
      { 'facebook.id' => {'$in' => Array(self['facebook_friends'])} }
    ])
    self.class.find(query, options)
  end

  def movies_from_friends(options = {})
    friends_ids = friends({}, :fields => %w[_id], :transformer => nil).map { |f| f['_id'] }
    watches = self.class.collection['watched'].
      find({'user_id' => {'$in' => friends_ids}}, :fields => %w[movie_id liked], :sort => [:_id, :desc])

    movie_ids = watches.map { |w| w['movie_id'] }.uniq
    Movie.find(movie_ids)
  end

  def friends_who_watched(movie)
    watches = self.class.collection['watched'].
      find({'movie_id' => movie.id}, :fields => %w[user_id liked], :sort => [:_id, :desc])

    user_ids = watches.map { |w| w['user_id'] }
    friends(user_ids)
  end
end
