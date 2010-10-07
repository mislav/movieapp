module FactoryMethods
  def build(*args)
    described_class.new(*args)
  end

  def create(*args, &block)
    described_class.create(*args, &block)
  end
end

RSpec.configure do |config|
  config.include FactoryMethods
end
