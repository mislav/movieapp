require 'mingo_set_property'

module User::Friends
  extend ActiveSupport::Concern

  included do
    extend Mingo::SetProperty
    # the values of these properties are dynamic Set objects that automatically
    # update the database when elements are added or removed
    property :friends_added, :type => :set
    property :friends_removed, :type => :set
  end

  def add_friend(user_or_id)
    id = BSON::ObjectId.from_object(user_or_id)
    friends_added << id
    friends_removed.delete id
  end
  
  def remove_friend(user_or_id)
    id = BSON::ObjectId.from_object(user_or_id)
    friends_removed << id
    friends_added.delete id
  end
  
  def twitter_friends=(ids)
    self['twitter_friends'] = ids.map { |id| id.to_i }
  end

  def facebook_friends=(ids)
    self['facebook_friends'] = ids.map { |id| id.to_s }
  end

  # Returns true if the receiver is following the given user by any means
  # (Twitter following, Facebook friendship, explicit following here on the site).
  def following?(user)
    ( following_on_facebook?(user) or following_on_twitter?(user) or following_directly?(user) ) and
      not unfollowed?(user)
  end

  def following_on_facebook?(user)
    self['facebook_friends'] && user.from_facebook? && self['facebook_friends'].include?(user['facebook']['id'])
  end

  def following_on_twitter?(user)
    self['twitter_friends'] && user.from_twitter? && self['twitter_friends'].include?(user['twitter']['id'])
  end

  def following_directly?(user)
    friends_added? && friends_added.include?(user.id)
  end

  def unfollowed?(user)
    friends_removed? && friends_removed.include?(user.id)
  end

  # Returns a cursor representing people who this user follows.
  #
  # Extra conditions can be passed through the `query` parameter.
  # This parameter can also be an array of user ids to scope the search to.
  # The `options` hash is forwarded to the `Mingo.find` method.
  #
  # "Friends" are those connected through Twitter or Facebook or those
  # explicitly added via `add_friend`.
  #
  # The collection excludes people explicitly removed via `remove_friend`.
  def friends(query = {}, options = {})
    query = {:_id => {'$in' => query.to_a}} if query.respond_to? :<<

    # initial condition matches friends by twitter/facebook ids
    query = query.merge('$or' => [
      { 'twitter.id' => {'$in' => Array(self['twitter_friends'])} },
      { 'facebook.id' => {'$in' => Array(self['facebook_friends'])} }
    ])

    # add conditions for explicit follows
    query['$or'] << { '_id' => {'$in' => friends_added.to_a} } if friends_added?

    # explicit unfollows
    if friends_removed?
      if query.has_key? :_id
        # case in which find is scoped to a set of user ids
        query[:_id]['$in'] = query[:_id]['$in'] - friends_removed.to_a
      else
        query[:_id] = {'$nin' => friends_removed.to_a} 
      end
    end

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
