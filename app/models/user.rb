class User
  include MongoMapper::Document
  
  key :username, String
  
  def self.find_or_create_from_twitter(twitter_user)
    first(:username => twitter_user.screen_name) || create(:username => twitter_user.screen_name)
  end
end
