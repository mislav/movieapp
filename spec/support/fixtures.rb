module FixtureLoader
  def read_fixture(file)
    File.read RSpec.configuration.fixtures_path + file
  end
end

RSpec.configure do |config|
  config.include FixtureLoader
  config.add_setting :fixtures_path, :default => Rails.root + 'spec/fixtures'
end
