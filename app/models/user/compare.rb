class User::Compare
  extend ActiveSupport::Memoizable
  ALGORITHM_VERSION = 4

  def self.compatibility(*users)
    users = users.sort_by { |u| u.id.to_s }
    new(*users).compatibility
  end

  attr_reader :user1, :user2

  def initialize(user1, user2)
    @user1 = user1
    @user2 = user2
    @scope = nil
  end

  def cache_key
    [@user1.watched.cache_key, :compare, @user2.watched.cache_key].to_param
  end

  def scoped(num)
    @scope = num
    begin
      yield self
    ensure
      @scope = nil
    end if block_given?
    return self
  end

  def scoped?
    !!@scope
  end

  def method_missing(method, *args, &block)
    if scoped? and method !~ /\d[?!]?$/
      method = method.to_s.sub(/[?!]?$/, "#{@scope}\\0")
      send(method, *args, &block)
    else
      super
    end
  end

  def username1
    @user1.username
  end

  def username2
    @user2.username
  end

  def watched_count1
    @user1.watched.count
  end
  memoize :watched_count1

  def watched_count2
    @user2.watched.count
  end
  memoize :watched_count2

  def in_common_count
    movie_intersection.size
  end

  def movies_both_liked
    ids = movie_intersection.map { |movie_id, (liked1, liked2)|
      movie_id if liked1 == true and liked2 == true
    }.compact
    Movie.find ids.sample(60)
  end
  
  def movies_to_watch
    to_watch = User.collection['to_watch'].find('user_id' => {'$in' => [user1.id, user2.id]})
    ids = to_watch.map { |doc| doc['movie_id'] }.select_occurring(2)
    Movie.find ids.sample(60)
  end

  def score
    points = movie_intersection.inject(0) do |s, (movie, (like1, like2))|
      if like1 == like2
        s + 5
      elsif !like1.nil? and !like2.nil?
        s - 1
      elsif like1 != false and like2 != false
        s + 3
      else
        s + 2
      end
    end

    points / (in_common_count * 5).to_f
  end

  def common_factor
    return 0.8 if in_common_count == 1
    ratio = in_common_count / [watched_count1, watched_count2].min.to_f
  end
  
  def margin_of_error
    return 0.7 if in_common_count == 1
    1 / in_common_count.to_f
  end

  def compatibility
    Cache.fetch [self, :compatibility, ALGORITHM_VERSION], expires_in: 1.day do
      return nil if in_common_count.zero?

      percentage = (Math.sqrt(score * common_factor) - margin_of_error) * 100
      [0, percentage].max
    end
  end
  memoize :compatibility

  def movie_intersection
    watched1 = user1.watched.send :load_join
    watched2 = user2.watched.send :load_join
    ids2 = watched2.map {|d| d['movie_id'] }

    hash = watched1.each_with_object({}) do |doc, hash|
      id = doc['movie_id']
      hash[id] = [doc['liked']] if ids2.include? id
    end
    watched2.each_with_object(hash) do |doc, hash|
      id = doc['movie_id']
      hash[id] << doc['liked'] if hash.key? id
    end

    hash
  end
  memoize :movie_intersection

  def fav_directors1
    find_directors user1.watched.liked(:transformer => nil, :fields => 'directors')
  end
  memoize :fav_directors1

  def fav_directors2
    find_directors user2.watched.liked(:transformer => nil, :fields => 'directors')
  end
  memoize :fav_directors2

  def find_directors(cursor)
    Movie.directors_of_movies(cursor).
      select {|name, count| count > 1 }.map(&:first).first(3)
  end
end
