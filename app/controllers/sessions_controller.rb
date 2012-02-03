require 'omniauth/auth_hash'
require 'ostruct'

class SessionsController < ApplicationController

  skip_before_filter :login_from_token

  # for offline testing purposes only
  def instant_login
    user = Rails.configuration.twitter.test_user
    signup_user OmniAuth::AuthHash.new(provider: 'twitter',
      uid: user.id,
      info: { name: user.name, nickname: user.screen_name },
      extra: { raw_info: user })

    redirect_to watched_url(current_user)
  end

  def connect
    session[:connecting_with] = params[:network] # facebook or twitter
    session[:following_count] = current_user.friends.count

    redirect_to login_path(params[:network])
  end

  def finalize
    signup_user request.env['omniauth.auth']

    if network = session[:connecting_with]
      new_friends = current_user.friends.count - session[:following_count]
      if new_friends.zero?
        message = "Successfully connected #{network.capitalize}"
      else
        message = "Successfully connected with #{new_friends} people from #{network.capitalize}"
      end

      session.delete(:connecting_with)
      session.delete(:following_count)

      redirect_to following_url, notice: message
    else
      redirect_to watched_url(current_user)
    end
  end

  def auth_failure
    render 'shared/error', status: 500, locals: {
      error: OpenStruct.new(message: params[:message])
    }
  end

  def logout
    if logged_in? and cookies[:login_token].present?
      current_user.delete_login_token cookies[:login_token]
      cookies.delete :login_token
    end
    self.current_user = nil

    redirect_to root_path
  end
  
  private

  def signup_user(auth)
    if self.current_user = User.login_from_provider(auth, current_user)
      if cookies[:login_token].blank? or !current_user.has_login_token?(cookies[:login_token])
        cookies.signed.permanent[:login_token] = {
          value: current_user.generate_login_token,
          httponly: true
        }
      end
    end
  end

end
