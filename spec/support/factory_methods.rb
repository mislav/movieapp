$user_id = 0

module FactoryMethods
  def build(*args)
    described_class.new(*args)
  end

  def create(*args, &block)
    if described_class.name == 'User'
      user_create(*args, &block)
    else
      described_class.create(*args, &block)
    end
  end

  def user_create(attributes = {}, &block)
    User.create({username: "test#{$user_id += 1}"}.update(attributes), &block)
  end
end

RSpec.configure do |config|
  config.include FactoryMethods
end
