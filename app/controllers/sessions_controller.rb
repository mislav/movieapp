class SessionsController < ApplicationController

  # for offline testing purposes only
  def instant_login
    session[:twitter_user] = Rails.configuration.twitter.test_user
    redirect_to root_path
  end

  def logout
    twitter_logout
    facebook_logout
    redirect_to root_path
  end

end