require 'net/http'
require 'json'
require 'oauth'
require 'oauth2'

module User::Social
  extend ActiveSupport::Concern

  TwitterFields = %w[name location created_at url utc_offset time_zone id lang protected followers_count screen_name]

  def twitter_info=(info)
    self['twitter'] = info.to_hash.slice(*TwitterFields).tap do |data|
      self.username ||= data['screen_name']
      self.name ||= data['name']
    end
  end

  def from_twitter?
    !!self['twitter']
  end

  def from_facebook?
    !!self['facebook']
  end

  def following_on_twitter?(user)
    self.twitter_friends.include? user['twitter']['id'] if user.from_twitter?
  end

  def following_on_facebook?(user)
    self.facebook_friends.include? user['facebook']['id'] if user.from_facebook?
  end

  FACEBOOK_FIELDS = %w[id username link name email website timezone location gender]

  def facebook_info=(info)
    self['facebook'] = info.to_hash.slice(*FACEBOOK_FIELDS).tap do |data|
      self.username ||= data['username'] || data['link'].scan(/[\w.]+/).last
      self.name ||= data['name']
    end
  end

  def refresh_social_connections
    fetch_twitter_friends
    fetch_facebook_friends
  end

  def fetch_twitter_friends
    if self['twitter_token']
      client = ::User::Social.twitter_client(self['twitter_token'])
      response = client.get('/1/friends/ids.json')
      ids_data = JSON.parse response.body
      self.twitter_friends = ids_data['ids']
    end
  end

  def self.twitter_client(token_values)
    config = Movies::Application.config.twitter
    token, secret, = token_values
    oauth = OAuth::Consumer.new config.consumer_key, config.secret,
      site: 'https://api.twitter.com'
    OAuth::AccessToken.new(oauth, token, secret)
  end

  def fetch_facebook_friends
    if self['facebook_token']
      client = ::User::Social.facebook_client(self['facebook_token'])
      response = client.get('/me', params: {fields: 'friends'}) # 'movies,friends'
      user_info = JSON.parse response.body
      self.facebook_friends = user_info['friends']['data'].map { |f| f['id'] }
      # watched.import_from_facebook user_info['movies']['data']
    end
  end

  def self.facebook_client(token_values)
    config = Movies::Application.config.facebook
    token, = token_values
    oauth = OAuth2::Client.new config.app_id, config.secret,
      site: 'https://graph.facebook.com',
      token_url: '/oauth/access_token'

    OAuth2::AccessToken.new(oauth, token, mode: :query, param_name: 'access_token')
  end

  def twitter_url
    'http://twitter.com/' + self['twitter']['screen_name']
  end

  # 73x73 px
  def twitter_picture
    self['twitter_picture'] || begin
      name = self['twitter']['screen_name']
      img = get_redirect_target "http://api.twitter.com/1/users/profile_image/#{name}?size=bigger"
      if img and img !~ /default_profile_/
        self['twitter_picture'] = img
        self.save
        img
      end
    end
  end

  def facebook_url
    self['facebook']['link']
  end

  # 100x? px
  def facebook_picture
    "http://graph.facebook.com/#{self['facebook']['id']}/picture?type=normal"
  end

  # either Twitter of Facebook picture
  def picture_url
    url = from_twitter? && twitter_picture
    url ||= from_facebook? && facebook_picture
    url.presence
  end

  def picture?
    picture_url.present?
  end

  module ClassMethods
    # provider: twitter or facebook
    def find_from_provider(provider, id)
      case provider
      when 'twitter'  then id = id.to_i
      when 'facebook' then id = id.to_s
      end
      first("#{provider}.id" => id)
    end

    def login_from_provider(auth, current_user = nil)
      if user = find_from_provider(auth.provider, auth.uid)
        if current_user and current_user != user
          user = merge_accounts(user, current_user)
        end
      else
        user = current_user || self.new
      end

      case auth.provider
      when 'twitter'
        user.twitter_info = auth.extra.raw_info
        user['twitter_token'] = [auth.credentials.token, auth.credentials.secret] if auth.credentials
      when 'facebook'
        user.facebook_info = auth.extra.raw_info
        user['facebook_token'] = [auth.credentials.token, auth.credentials.secret] if auth.credentials
      end

      user.refresh_social_connections
      user.save
      return user
    end
  end

  private

  def get_redirect_target(url)
    return nil if Movies.offline?
    # TODO: cache results for 1 day
    url = URI.parse url unless url.respond_to? :request_uri
    response = Net::HTTP.start(url.host, open_timeout: 2) {|http| http.get url.request_uri }
    response['location'] if response.is_a? Net::HTTPRedirection
  rescue Timeout::Error
    NeverForget.log($!, url: url)
    return nil
  end
end
