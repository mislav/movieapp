class User
  include MongoMapper::Document
  
  key :username, String
  key :to_watch, Array
  
  def self.find_or_create_from_twitter(twitter_user)
    first(:username => twitter_user.screen_name) || create(:username => twitter_user.screen_name)
  end
  
  def movies_to_watch
    Movie.all(:id => to_watch)
  end
  
  def add_movie_to_watch(movie)
    self.to_watch << movie.id unless to_watch.include? movie.id
  end
  
  # I watched this
  # - current date
  # - liked it/didn't like
  
  # to watch
end
