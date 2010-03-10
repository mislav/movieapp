class User
  include MongoMapper::Document
  
  many :views do
    def create(attributes)
      self.concat self.klass.create(attributes)
    end
  end
  
  many :to_watch, :class => Movie
  
  key :username, String
  
  def self.find_or_create_from_twitter(twitter_user)
    first(:username => twitter_user.screen_name) || create(:username => twitter_user.screen_name)
  end
  
  def movies_to_watch
    Movie.all(:id => to_watch)
  end
  
  def add_movie_to_watch(movie)
    self.to_watch << movie.id unless to_watch.include? movie.id
  end
end
