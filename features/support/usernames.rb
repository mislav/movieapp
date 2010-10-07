module ManyUsernames
  def each_user(usernames, factory = false)
    usernames.scan(/(?:^|\W)@(\w+)/).flatten.each do |name|
      user = User.first(:username => name)
      
      unless user
        if factory
          user = create_user(:username => name)
        else
          raise "can't find user with login '#{name}'" unless user
        end
      end
      
      yield user
    end
  end
  
  def self.generate_id
    @generate_id ||= 0
    @generate_id += 1
  end
  
  def create_user(attributes = {})
    User.create(attributes) do |user|
      user.name ||= 'Sin Nombre'
      user.twitter_info = { 'id' => ManyUsernames.generate_id }
      user.facebook_info = { 'id' => ManyUsernames.generate_id }
    end
  end
  
  def find_or_create_user(username, attributes = {})
    User.first(:username => username) || create_user(attributes.merge(:username => username))
  end
end

World(ManyUsernames)