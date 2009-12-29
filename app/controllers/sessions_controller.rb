class SessionsController < ApplicationController
  
  def logout
    [:oauth_consumer, :access_token, :twitter_user].each { |key| session[key] = nil }
    redirect_to root_path
  end
  
end