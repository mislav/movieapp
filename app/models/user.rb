class User < Mingo
  property :username
  property :name
  
  def username=(value)
    self['username'] = self.class.generate_username(value)
  end
  
  def to_param
    username
  end
  
  def twitter_friends=(ids)
    self['twitter_friends'] = ids
  end
  
  def friends(query = {}, options = {})
    query = query.merge('twitter.id' => {'$in' => Array(self['twitter_friends'])})
    self.class.find(query, options)
  end
  
  def movies_from_friends
    users = friends({'watched' => {'$exists' => true}}, :fields => :watched)
    movie_ids = friends.map { |u| u.watched.object_ids }.flatten.uniq
    Movie.find '_id' => {'$in' => movie_ids}
  end
  
  # 'to_watch' => [movie_id1, movie_id2, ...]
  many :to_watch, Movie
  
  # 'watched' => [{ 'movie' => movie_id1, 'liked' => true }, { ... }, ...]
  many :watched, Movie do
    # defines how to collect IDs of movies to load from the databae
    def object_ids
      @embedded.map { |watched| watched['movie'] }
    end
    
    # defines how to convert given object (or document) to a custom
    # construct to be embedded directly in parent document
    def convert(doc)
      if doc.is_a?(Hash) and not doc.is_a?(Mingo) then doc
      else
        raise ArgumentError, "got #{doc.inspect}" unless doc.is_a? Mingo or doc.is_a? BSON::ObjectId
        {'movie' => doc.id, 'time' => Time.now.utc}
      end
    end
    
    def include?(doc)
      @embedded.any? { |e| e['movie'] == doc.id }
    end
    
    # overload delete to find matching embedded value
    def delete(doc)
      doc = @embedded.find { |e| e['movie'] == doc.id }
      super(doc) if doc
    end
    
    # overload push operator to remove matching movie from `to_watch` list
    def <<(doc)
      super.tap do |result|
        @parent.to_watch.delete(doc.instance_of?(Hash) ? doc['movie'] : doc)
      end
    end
    
    # custom method that wraps `<<` to add a movie with rating
    def add_with_rating(movie, liked)
      liked = case liked.downcase
        when 'yes', 'true', '1' then true
        when 'no', 'false', '0' then false
        else nil
        end if liked.respond_to? :downcase

      self << convert(movie).update('liked' => liked)
    end
    
    def rating_for(movie)
      metadata = @embedded.find { |e| e['movie'] == movie.id }
      metadata['liked']
    end
    
    # defines an anonymous module that each movie in this collection
    # will be "decorated" (extended) with after being loaded
    decorate_with do
      attr_accessor :liked, :time_added
      def liked?() !!@liked end
    end
    
    # defines a block that will yield for each movie loaded from
    # the database, useful for decorating movies with extra information
    decorate_each do |movie, embedded|
      metadata = embedded.find { |e| e['movie'] == movie.id }
      movie.liked = metadata['liked']
      movie.time_added = metadata['time']
    end
    
    def liked
      liked_ids = @embedded.map { |watched| watched['movie'] if watched['liked'] }.compact
      @model.find({:_id => {'$in' => liked_ids}}, find_options)
    end
  end
  
  TwitterFields = %w[name location created_at url utc_offset time_zone id lang protected followers_count screen_name]
  
  def self.from_twitter(twitter)
    find_or_initialize_from_twitter(twitter).tap do |user|
      user['twitter'] = twitter.to_hash.slice(*TwitterFields)
      user.save
    end
  end
  
  def self.find_or_initialize_from_twitter(twitter)
    first('twitter.id' => twitter.id) ||
      new(:username => twitter.screen_name, :name => twitter.name)
  end
  
  def self.generate_username(name)
    name.dup.tap do |unique_name|
      unique_name.sub!(/\d*$/) { $&.to_i + 1 } while username_taken?(unique_name)
    end
  end
  
  def self.username_taken?(name)
    # TODO: take reserved routes into account
    find(:username => name).has_next?
  end
  
  def self.get_id(obj)
    case obj
    when String then BSON::ObjectId(obj)
    when BSON::ObjectId then obj
    else obj.id
    end
  end
end
