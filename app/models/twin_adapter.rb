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
  
  class << self
    include ActionDispatch::Routing::UrlFor
    include Rails.application.routes.url_helpers

    private
    
    def status_from_watched_movie(movie, item_id, collection)
      people = collection.people_who_watched(movie)
      user = people.first
      
      text = ''
      text << people.map { |person| user_name(person) }.to_sentence << ' ' if people.length > 1
      text << movie.title
      text << " (#{movie.year})" if movie.year
      
      if people.length == 1
        case collection.rating_for(movie, user)
        when TrueClass  then text << " and liked it"
        when FalseClass then text << " but didn't like it"
        else                 text << "… thought it was meh"
        end
      end
      
      {
        id: item_id.to_s, id_str: item_id.to_s,
        text: text, user: user,
        created_at: item_id.generation_time
      }
    end
    
    def user_name(user)
      user.username !~ /\D/ ? user.name : user.username
    end
  end
  
  default_url_options[:host] = 'movi.im'
  
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

User.class_eval do
  def to_twin_hash
    created = self.created_at
    num_id = created.to_i
    {
      id: num_id, id_str: num_id.to_s,
      screen_name: self.username, name: self.name,
      url: TwinAdapter.watched_url(username: self.username),
      profile_image_url: self.picture_url,
      created_at: created
    }
  end
end
