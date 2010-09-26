class SessionsController < ApplicationController

  # for offline testing purposes only
  def instant_login
    user = Rails.configuration.twitter.test_user
    session[:twitter_user] = user
    redirect_to watched_path(current_user)
  end
  
  def after_twitter
    if twitter_user
      response = twitter_client.get('/1/friends/ids.json')
      friends_ids = Yajl::Parser.parse response.body
      current_user.twitter_friends = friends_ids
      current_user.save
    end
    
    redirect_to watched_url(current_user)
  end

  def logout
    twitter_logout
    facebook_logout
    redirect_to root_path
  end

end