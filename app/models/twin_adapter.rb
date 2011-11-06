# encoding: utf-8
module TwinAdapter
  def self.statuses(params, current_user)
    conditions = params.slice(:max_id, :since_id)
    movies = current_user.movies_from_friends(conditions).limit(params[:count] || 20)
    movies.each.with_index.map do |movie, i|
      watches = movies.send(:watches, movie_id: movie.id)
      item_id = (i.zero? ? watches.first : watches.last)['_id']
      status_from_watched_movie(movie, item_id, movies)
    end
  end
  
  def self.mentions(params, current_user)
    []
  end
  
  class << self
    include ActionDispatch::Routing::UrlFor
    include Rails.application.routes.url_helpers

    private
    
    def status_from_watched_movie(movie, item_id, collection)
      people = collection.people_who_watched(movie)
      user = people.first
      
      text = ''
      text << people.map { |person| user_name(person) }.to_sentence << ' watched ' if people.length > 1
      text << title_with_year(movie)
      text << rating_comment(collection.rating_for(movie, user)) if people.length == 1
      
      {
        id: item_id.to_s, id_str: item_id.to_s,
        text: text, user: user,
        created_at: item_id.generation_time
      }
    end
    
    def rating_comment(rating)
      case rating
      when TrueClass  then " and liked it"
      when FalseClass then " but didn't like it"
      else                 ", thought it was meh"
      end
    end
    
    def find_movie_from_watched(watch_id)
      unless watch = User.collection['watched'].find_one(_id: BSON::ObjectId(watch_id))
        raise "could not find watched document #{status_id.inspect}"
      end
      Movie.first(watch['movie_id'])
    end
    
    def user_name(user)
      user.username !~ /\D/ ? user.name : user.username
    end
    
    def title_with_year(movie)
      text = movie.title.dup
      text << " (#{movie.year})" if movie.year
      text
    end
  end
  
  default_url_options[:host] = 'movi.im'
  
  def self.favorites(params, current_user, user_id = nil)
    user = user_id ? find_by_id(user_id) : current_user
    movies = user.to_watch(since_id: params[:since_id]).limit(20).page(params[:page].to_i + 1)

    movies.each_with_link.map do |movie, link_doc|
      item_id = link_doc['_id']
      text = title_with_year(movie)

      { id: item_id.to_s, id_str: item_id.to_s,
        text: text, user: user,
        created_at: item_id.generation_time
      }
    end
  end
  
  def self.create_favorite(status_id, current_user)
    movie = find_movie_from_watched(status_id)
    current_user.to_watch << movie unless current_user.watched.include? movie
  end
  
  def self.destroy_favorite(status_id, current_user)
    movie = find_movie_from_watched(status_id)
    current_user.to_watch.delete movie
  end
  
  def self.retweet(status_id, current_user)
    # TODO
  end
  
  def self.status_update(params, current_user)
    unless ref_id = params[:in_reply_to_status_id]
      raise "no can do without :in_reply_to_status_id"
    end
    doc = nil
    %w[watched to_watch].each do |where|
      doc = User.collection[where].find_one(_id: BSON::ObjectId(ref_id)) and break
    end
    raise "didn't find document: #{ref_id.inspect}" unless doc

    movie = Movie.first(doc['movie_id'])
    rating = case params[:status]
    when /\bmeh\b/ then nil
    when /\bdid(n'?t| not)\b/ then false
    when /\bliked\b/ then true
    else
      raise "can't detect rating: #{params[:status].inspect}"
    end
    
    current_user.watched.rate_movie(movie, rating)
    item_id = User.collection['watched'].find_one({user_id: current_user.id, movie_id: movie.id}, sort: [:_id, -1])['_id']
    text = "watched #{title_with_year(movie)} #{rating_comment(rating)}"
    
    { id: item_id.to_s, id_str: item_id.to_s,
      in_reply_to_status_id: ref_id,
      text: text, user: current_user,
      created_at: item_id.generation_time
    }
  end
  
  def self.authenticate(username, password)
    # TODO: password auth
    ::User[username] if "twin" == password
  end
  
  def self.twin_token(user)
    user.generate_login_token
  end
  
  def self.find_by_twin_token(token)
    ::User.find_by_login_token token
  end
  
  def self.find_by_id(user_id)
    time = Time.at(user_id.to_i).utc
    ::User.first(:_id => {'$gte' => BSON::ObjectId.from_time(time)})
  end
  
  def self.find_by_username(name)
    ::User[name]
  end
end
