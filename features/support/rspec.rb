require 'cucumber/rails/rspec'

# This plugs RSpec's mocking/stubbing framework into cucumber
require 'rspec/mocks'
RSpec::Mocks.setup(Object.new)

World(RSpec::Mocks::ExampleMethods)

After do
  RSpec::Mocks.verify
  RSpec::Mocks.teardown
end
