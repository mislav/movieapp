require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include WebMock::Matchers

  config.before :each do
    WebMock.reset_webmock
  end
end

module WebMockWorld
  include WebMock::API
  include WebMock::Matchers
end

World(WebMockWorld)
