require 'net/http'
require 'json'
require 'oauth'
require 'oauth2'
require 'hashie/mash'

module ServiceFetcher

  extend self

  def twitter_config
    Movies::Application.config.twitter
  end

  def twitter_client(token_values)
    token, secret, = token_values
    oauth = OAuth::Consumer.new twitter_config.consumer_key, twitter_config.secret,
      site: 'https://api.twitter.com'
    OAuth::AccessToken.new(oauth, token, secret)
  end

  def get_twitter_friends(token_values)
    client = twitter_client(token_values)
    response = client.get('/1/friends/ids.json')
    process_json_response(response.body, response.code.to_i)
  rescue => error
    error
  end

  def facebook_config
    Movies::Application.config.facebook
  end

  def facebook_client(token_values)
    token, = token_values
    oauth = OAuth2::Client.new facebook_config.app_id, facebook_config.secret,
      site: 'https://graph.facebook.com',
      raise_errors: false

    OAuth2::AccessToken.new(oauth, token, mode: :query, param_name: 'access_token')
  end

  def get_facebook_info(token_values, params)
    client = facebook_client(token_values)
    response = client.get('/me', params: params)
    process_json_response(response.body, response.status)
  rescue => error
    error
  end

  def get_twitter_profile_image(screen_name)
    get_redirect_location "http://api.twitter.com/1/users/profile_image/#{screen_name}?size=bigger"
  end

  private

  def process_json_response(body, status)
    data = JSON.parse body rescue $!
    data = Hashie::Mash.new data if data.is_a? Hash

    data.singleton_class.class_eval "def status() #{status} end"
    data
  end

  def get_redirect_location(url)
    return nil if Movies.offline?
    url = URI.parse url unless url.respond_to? :request_uri
    response = Net::HTTP.start(url.host, open_timeout: 2) {|http| http.get url.request_uri }
    response['location'] if response.is_a? Net::HTTPRedirection
  rescue Timeout::Error
    NeverForget.log($!, url: url)
    return nil
  end

end
