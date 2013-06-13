class User < Mingo
  property :username
  property :name
  
  collection.ensure_index :username, unique: true
  
  include Mingo::Timestamps
  include Social
  include Friends
  
  include ToWatch
  include Watched

  property :ignored_recommendations, :type => :set

  def username=(value)
    self['username'] = self.class.generate_username(value)
  end
  
  def to_param
    username
  end
  
  def admin?
    Movies::Application.config.admins.include? username
  end
  
  def self.[](username)
    first(username: username)
  end
  
  def self.merge_accounts(user1, user2)
    if user2.created_at < user1.created_at
      user2.merge_account(user1)
    else
      user1.merge_account(user2)
    end
  end
  
  def merge_account(other)
    other.each do |key, value|
      self[key] = value if value and self[key].nil?
    end
    [self.class.collection['watched'], self.class.collection['to_watch']].each do |collection|
      collection.update({'user_id' => other.id}, {'$set' => {'user_id' => self.id}}, :multi => true)
    end
    self.reset_counter_caches!
    other.destroy
    return self
  end

  def reset_counter_caches!
    watched.reset_counter_cache
    to_watch.reset_counter_cache
    true
  end
  
  def self.generate_username(name)
    name.dup.tap do |unique_name|
      unique_name.sub!(/\d*$/) { $&.to_i + 1 } while username_taken?(unique_name)
    end
  end
  
  Reserved = %w[following followers favorites timeline search home signup]
  
  def self.reserved_names_from_routes
    Rails.application.routes.routes.map { |route|
      unless route.defaults[:controller] == "rails/info"
        route.path.spec.to_s.match(/^\/(\w+)/) && $1
      end
    }.compact.uniq
  end
  
  def self.apply_reserved_names_from_routes
    Reserved.concat reserved_names_from_routes
  end
  
  apply_reserved_names_from_routes if Rails.env.development?
  
  def self.username_taken?(name)
    Reserved.include?(name) or find(:username => name).has_next?
  end

  property :login_tokens, :type => :set

  def generate_login_token
    token = SecureRandom.urlsafe_base64
    login_tokens << token
    token
  end

  def has_login_token?(token)
    login_tokens.include? token
  end

  def self.find_by_login_token(token)
    first(:login_tokens => token)
  end

  def delete_login_token(token)
    login_tokens.delete token
  end

  def to_twin_hash
    created = self.created_at
    num_id = created.to_i
    {
      id: num_id, id_str: num_id.to_s,
      screen_name: self.username, name: self.name,
      url: TwinAdapter.watched_url(username: self.username),
      profile_image_url: self.picture_url,
      created_at: created
    }
  end
end
