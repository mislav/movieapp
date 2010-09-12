class SessionsController < ApplicationController

  # for offline testing purposes only
  def instant_login
    user = Rails.configuration.twitter.test_user
    session[:twitter_user] = user
    redirect_to watched_path(current_user)
  end

  def logout
    twitter_logout
    facebook_logout
    redirect_to root_path
  end

end