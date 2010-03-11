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
end
