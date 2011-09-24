require 'net/http'
require 'yajl'

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

  def facebook_info=(info)
    self['facebook'] = info.to_hash.tap do |data|
      self.username ||= data['link'].scan(/[\w.]+/).last
      self.name ||= data['name']
    end
  end

  def fetch_twitter_info(twitter_client)
    response = twitter_client.get('/1/friends/ids.json')
    friends_ids = Yajl::Parser.parse response.body
    self.twitter_friends = friends_ids
    save
  end

  def fetch_facebook_info(facebook_client)
    response_string = facebook_client.get('/me', :fields => 'friends') # 'movies,friends'
    user_info = Yajl::Parser.parse response_string
    self.facebook_friends = user_info['friends']['data'].map { |f| f['id'] }
    # watched.import_from_facebook user_info['movies']['data']
    save
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
    def from_twitter(twitter)
      login_from_twitter_or_facebook(twitter, nil)
    end

    def from_facebook(facebook)
      login_from_twitter_or_facebook(nil, facebook)
    end

    def find_from_twitter_or_facebook(twitter_info, facebook_info)
      if twitter_info or facebook_info
        first({}.tap { |conditions|
          conditions['twitter.id'] = twitter_info.id if twitter_info
          conditions['facebook.id'] = facebook_info.id if facebook_info
        })
      end
    end

    def login_from_twitter_or_facebook(twitter_info, facebook_info)
      raise ArgumentError unless twitter_info or facebook_info
      twitter_user = twitter_info && first('twitter.id' => twitter_info.id)
      facebook_user = facebook_info && first('facebook.id' => facebook_info.id)

      if twitter_user.nil? and facebook_user.nil?
        self.new
      elsif twitter_user == facebook_user or facebook_user.nil?
        twitter_user
      elsif twitter_user.nil?
        facebook_user
      else
        merge_accounts(twitter_user, facebook_user)
      end.
        tap do |user|
          user.twitter_info = twitter_info if twitter_info
          user.facebook_info = facebook_info if facebook_info
          user.save
        end
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
