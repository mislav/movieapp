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

  FACEBOOK_FIELDS = %w[id name timezone]

  def facebook_info=(info)
    self['facebook'] = info.to_hash.slice(*FACEBOOK_FIELDS).tap do |data|
      self.username ||= data['username']
      self.name ||= data['name']

      if info['picture'] && !info['picture']['data']['is_silhouette']
        data['picture'] = info['picture']['data']['url']
      end
    end
  end

  def refresh_social_connections
    fetch_twitter_friends
    fetch_facebook_friends
  end

  def fetch_twitter_friends
    if self['twitter_token']
      data = ServiceFetcher.get_twitter_friends(self['twitter_token'])
      if data.respond_to? :status
        case data.status
        when 200
          self.twitter_friends = data.ids
        when 401
          # the token seems no longer valid
          self['twitter_token'] = nil
        else
          raise "unhandled status: #{data.status.inspect}"
        end
      elsif data.is_a? Exception
        raise data
      end
    end
  rescue StandardError
    NeverForget.log($!, user_id: self.id)
  end

  def fetch_facebook_friends
    if self['facebook_token']
      data = ServiceFetcher.get_facebook_info(self['facebook_token'], fields: 'friends')
      if data.respond_to? :status
        case data.status
        when 200
          self.facebook_friends = data.friends.data.map(&:id)
          # watched.import_from_facebook data.movies.data
        when 401
          # the token seems no longer valid
          self['facebook_token'] = nil
        else
          raise "unhandled status: #{data.status.inspect}"
        end
      elsif data.is_a? Exception
        raise data
      end
    end
  rescue StandardError
    NeverForget.log($!, user_id: self.id)
  end

  def twitter_url
    'http://twitter.com/' + self['twitter']['screen_name']
  end

  # 73x73 px
  def twitter_picture
    update_twitter_picture(:autosave) if twitter_picture_stale?
    self['twitter_picture']
  end

  def update_twitter_picture(autosave = false)
    img = ServiceFetcher.get_twitter_profile_image self['twitter']['screen_name']
    self['twitter_picture'] = img =~ /default_profile_/ ? nil : img
    self['twitter_picture_updated_at'] = Time.now
    self.save if autosave
  end

  def twitter_picture_stale?
    self['twitter_picture_updated_at'].nil? or
      self['twitter_picture_updated_at'] < 1.day.ago
  end

  def facebook_url
    self['facebook']['link']
  end

  # 100x? px
  def facebook_picture
    "https://graph.facebook.com/#{self['facebook']['id']}/picture?type=normal"
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

      # user.refresh_social_connections unless Movies.offline?
      user.save
      return user
    end
  end
end
