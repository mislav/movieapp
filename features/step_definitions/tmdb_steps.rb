require Rails.root + 'spec/support/fixtures'

World(FixtureLoader)

Given /^TMDB returns (?:nothing|"([^"]+)") for the terms "([^"]*)"$/ do |fixture, query|
  body = if fixture.blank?
    '["Nothing found."]'
  else
    read_fixture("tmdb-#{fixture}")
  end
  
  url = Tmdb::SEARCH_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :query => query
  
  stub_request(:get, url).to_return(:body => body, :status => 200)
end
