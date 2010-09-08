ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

module FixtureLoader
  def read_fixture(file)
    File.read RSpec.configuration.fixtures_path + file
  end
end

RSpec.configure do |config|
  config.extend FixtureLoader
  config.include FixtureLoader
  config.mock_with :rspec
  config.add_setting :fixtures_path, :default => Rails.root + 'spec/fixtures'
end
