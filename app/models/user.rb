class User < Mingo
  property :username
  property :name
  
  include Mingo::Timestamps
  include Social
  include Friends
  
  def username=(value)
    self['username'] = self.class.generate_username(value)
  end
  
  def to_param
    username
  end
  
  def admin?
    Movies::Application.config.admins.include? username
  end
  
  many :to_watch, self => 'user_id', 'movie_id' => Movie do
    def <<(doc)
      return self if include? doc
      super
    end
  end
  
  many :watched, self => 'user_id', 'movie_id' => Movie do
    # defines how to convert given object (or document) to a custom
    # construct to be embedded directly in parent document
    def convert(doc)
      if doc.is_a?(Hash) and not doc.is_a?(Mingo) then doc
      else
        raise ArgumentError, "got #{doc.inspect}" unless doc.is_a? Mingo or doc.is_a? BSON::ObjectId
        super(doc)
      end
    end
    
    # overload push operator to remove matching movie from `to_watch` list
    def <<(doc)
      doc = convert(doc)
      return self if include? doc['movie_id']

      super(doc).tap do |result|
        @parent.to_watch.delete doc['movie_id']
      end
    end
    
    # custom method that wraps `<<` to add a movie with rating
    def rate_movie(movie, liked)
      movie_id = movie.id
      liked = case liked.downcase
        when 'yes', 'true', '1' then true
        when 'no', 'false', '0' then false
        else nil
        end if liked.respond_to? :downcase

      if join_doc = find_join_doc(movie.id)
        join_collection.update({:_id => join_doc['_id']}, '$set' => {'liked' => liked})
      else
        self << convert(movie).update('liked' => liked)
      end
    end
    
    def rating_for(movie)
      find_join_doc(movie.id)['liked']
    end
    
    # defines an anonymous module that each movie in this collection
    # will be "decorated" (extended) with after being loaded
    decorate_with do
      attr_accessor :liked, :time_added
      def liked?() @liked end
    end
    
    # defines a block that will yield for each movie loaded from
    # the database, useful for decorating movies with extra information
    decorate_each do |movie, metadata|
      movie.liked = metadata['liked']
      movie.time_added = metadata['_id'].generation_time
    end
    
    def liked(options = {})
      liked_ids = object_ids { |d| d['liked'] == true }
      @model.find({:_id => {'$in' => liked_ids}}, find_options.merge(options))
    end
    
    def disliked(options = {})
      liked_ids = object_ids { |d| d['liked'] == false }
      @model.find({:_id => {'$in' => liked_ids}}, find_options.merge(options))
    end
    
    def import_from_facebook(movies)
      existing_ids = object_ids
      facebook_ids = movies.each { |movie| movie['id'].to_i }
      from_facebook = @model.find(:facebook_id => {'$in' => facebook_ids}).index_by { |m| m['facebook_id'] }
      
      movies.each do |movie|
        unless found = from_facebook[movie['id'].to_i]
          searched = @model.search movie['name']
          unless searched.empty?
            found = searched.first.tap { |m|
              m['facebook_id'] = movie['id'].to_i
              m.save
            }
          end
        end
        
        if found and not existing_ids.include? found.id
          time = Time.parse movie['created_time']
          self << convert(found).update('liked' => true, '_id' => BSON::ObjectId.from_time(time, :unique => true))
        end
      end
    end
    
    def minutes_spent
      result = @model.collection.group \
        :cond => {:_id => {'$in' => self.object_ids}},
        :initial => {:minutes => 0},
        :reduce => 'function(doc, prev) { if(doc.runtime) prev.minutes += doc.runtime; return prev }'
      
      result.first['minutes']
    end
  end
  
  
  def self.merge_accounts(user1, user2)
    if user2.created_at < user1.created_at
      user2.merge_account(user1)
    else
      user1.merge_account(user2)
    end
  end
  
  def merge_account(other)
    other.each do |key, value|
      self[key] = value if value and self[key].nil?
    end
    [self.class.collection['watched'], self.class.collection['to_watch']].each do |collection|
      collection.update({'user_id' => other.id}, {'$set' => {'user_id' => self.id}}, :multi => true)
    end
    self.reset_counter_caches
    other.destroy
    return self
  end
  
  def reset_counter_caches
    self['watched_count'] = watched.send(:join_cursor).count
    self['to_watch_count'] = to_watch.send(:join_cursor).count
  end
  
  def self.generate_username(name)
    name.dup.tap do |unique_name|
      unique_name.sub!(/\d*$/) { $&.to_i + 1 } while username_taken?(unique_name)
    end
  end
  
  Reserved = %w[following followers favorites timeline search home signup]
  
  def self.reserved_names_from_routes
    Rails.application.routes.routes.map { |route|
      unless route.defaults[:controller] == "rails/info"
        route.path.match(/^\/(\w+)/) && $1
      end
    }.compact.uniq
  end
  
  def self.apply_reserved_names_from_routes
    Reserved.concat reserved_names_from_routes
  end
  
  apply_reserved_names_from_routes if Rails.env.development?
  
  def self.username_taken?(name)
    Reserved.include?(name) or find(:username => name).has_next?
  end

  property :login_tokens, :type => :set

  def generate_login_token
    token = SecureRandom.urlsafe_base64
    login_tokens << token
    token
  end

  def has_login_token?(token)
    login_tokens.include? token
  end

  def self.find_by_login_token(token)
    first(:login_tokens => token)
  end

  def delete_login_token(token)
    login_tokens.delete token
  end
end
