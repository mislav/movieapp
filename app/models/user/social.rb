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
      self.username ||= data['link'].scan(/\w+/).last
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

  def facebook_url
    self['facebook']['link']
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
end
