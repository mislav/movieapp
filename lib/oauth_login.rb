require 'twitter'
require 'rack/request'
require 'hashie/mash'

class Twitter::OAuthLogin
  attr_reader :options
  
  DEFAULTS = {
    :login_path => '/login', :return_to => '/',
    :site => 'http://twitter.com', :authorize_path => '/oauth/authenticate'
  }
  
  def initialize(app, options)
    @app = app
    @options = DEFAULTS.merge options
  end
  
  def call(env)
    request = Request.new(env)
    
    if request.get? and request.path == options[:login_path]
      # detect if Twitter redirected back here
      if request[:oauth_verifier]
        handle_twitter_authorization(request) do
          @app.call(env)
        end
      else
        # user clicked to login; send them to Twitter
        redirect_to_twitter(request)
      end
    else
      @app.call(env)
    end
  end
  
  module Helpers
    def twitter_consumer
      token = OAuth::AccessToken.new(oauth_consumer, *session[:access_token])
      Twitter::Base.new token
    end
    
    def oauth_consumer
      OAuth::Consumer.new(*session[:oauth_consumer])
    end
    
    def twitter_user
      if session[:twitter_user]
        Hashie::Mash[session[:twitter_user]]
      end
    end
    
    def twitter_logout
      [:oauth_consumer, :access_token, :twitter_user].each { |key| session.delete key }
    end
  end
  
  class Request < Rack::Request
    # for storing :request_token, :access_token
    def session
      env['rack.session'] ||= {}
    end
    
    # SUCKS: must duplicate logic from the `url` method
    def url_for(path)
      url = scheme + '://' + host

      if scheme == 'https' && port != 443 ||
          scheme == 'http' && port != 80
        url << ":#{port}"
      end

      url << path
    end
  end
  
  protected
  
  def redirect_to_twitter(request)
    # create a request token and store its parameter in session
    token = oauth_consumer.get_request_token(:oauth_callback => request.url)
    request.session[:request_token] = [token.token, token.secret]
    # redirect to Twitter authorization page
    redirect token.authorize_url
  end
  
  def handle_twitter_authorization(request)
    # replace the request token in session with access token
    request_token = ::OAuth::RequestToken.new(oauth_consumer, *request.session[:request_token])
    access_token = request_token.get_access_token(:oauth_verifier => request[:oauth_verifier])
    
    # store access token and OAuth consumer parameters in session
    request.session.delete(:request_token)
    request.session[:access_token] = [access_token.token, access_token.secret]
    consumer = access_token.consumer
    request.session[:oauth_consumer] = [consumer.key, consumer.secret, consumer.options]
    
    # get and store authenticated user's info from Twitter
    twitter = Twitter::Base.new access_token
    request.session[:twitter_user] = twitter.verify_credentials.to_hash
    
    # pass the request down to the main app
    response = yield
    
    # check if the app implemented anything at :login_path
    if response[0].to_i == 404
      # if not, redirect to :return_to path
      redirect request.url_for(options[:return_to])
    else
      # use the response from the app without modification
      response
    end
  end
  
  def redirect(url)
    ["302", {'Location' => url, 'Content-type' => 'text/plain'}, []]
  end
  
  def oauth_consumer
    ::OAuth::Consumer.new options[:key], options[:secret],
      :site => options[:site], :authorize_path => options[:authorize_path]
  end
end
