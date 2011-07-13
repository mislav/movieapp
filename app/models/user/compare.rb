class User::Compare
  extend ActiveSupport::Memoizable

  attr_reader :user1, :user2

  def initialize(user1, user2)
    @user1 = user1
    @user2 = user2
    @scope = nil
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

  def watched_count2
    @user2.watched.count
  end

  def in_common_count
    movie_intersection.size
  end

  def movies_both_liked
    ids = movie_intersection.map { |movie_id, (liked1, liked2)|
      movie_id if liked1 == true and liked2 == true
    }.compact
    Movie.find ids.sample(60)
  end

  def score
    movie_intersection.inject(0) do |s, (movie, (like1, like2))|
      if like1 == like2
        s + 1
      elsif !like1.nil? and !like2.nil?
        s - 1
      else
        s
      end
    end
  end

  def compatibility
    total = in_common_count
    (score + total) / (total * 2).to_f * 100
  end

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
    find_directors movie_intersection.map { |movie_id, (liked, _)|
      movie_id unless liked == false
    }.compact
  end
  memoize :fav_directors1

  def fav_directors2
    find_directors movie_intersection.map { |movie_id, (_, liked)|
      movie_id unless liked == false
    }.compact
  end
  memoize :fav_directors2

  def find_directors(ids)
    Movie.directors_of_movies(ids).
      select {|name, count| count > 1 }.map(&:first).first(3)
  end
end
