ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'webmock/rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

# Enables existing Webmock stubs to work
VCR.turn_off!

RSpec.configure do |config|
  config.mock_with :rspec
  config.include WebMock::API
  config.extend VCR::RSpec::Macros
  config.extend Module.new {
    def use_vcr_cassette(*args)
      before(:all) { VCR.turn_on! }
      super
      after(:all) { VCR.turn_off! }
    end
  }
end
