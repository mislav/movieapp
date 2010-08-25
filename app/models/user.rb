class User < Mingo
  property :username
  property :name
  
  def username=(value)
    self['username'] = self.class.generate_username(value)
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
      if doc.instance_of?(Hash) then doc
      else {'movie' => doc.id, 'time' => Time.now.utc}
      end
    end
    
    # custom method that wraps `<<` to add a movie with rating
    def add_with_rating(movie, liked)
      self << convert(movie).update('liked' => liked)
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
  end
  
  TwitterFields = %w[name location created_at url utc_offset time_zone id lang protected followers_count screen_name]
  
  def self.from_twitter(twitter)
    user = first('twitter.screen_name' => twitter.screen_name)
    user ||= new(:username => twitter.screen_name, :name => twitter.name)
    user['twitter'] = twitter.to_hash.slice(*TwitterFields)
    user.save
    user
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
