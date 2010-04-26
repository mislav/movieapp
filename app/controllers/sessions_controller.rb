class SessionsController < ApplicationController

  def logout
    twitter_logout
    facebook_logout
    redirect_to root_path
  end

end