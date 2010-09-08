require 'webmock'
require 'rspec'

require 'webmock/adapters/rspec/request_pattern_matcher'
require 'webmock/adapters/rspec/webmock_matcher'
require 'webmock/adapters/rspec/matchers'
  
RSpec.configure do |config|
  config.include WebMock::Matchers

  config.before :each do
    WebMock.reset_webmock
  end
end

module WebMock
  def assertion_failure(message)
    raise RSPEC_NAMESPACE::Expectations::ExpectationNotMetError.new(message)
  end
end

module WebMockWorld
  include WebMock
  include WebMock::Matchers
end

World(WebMockWorld)
