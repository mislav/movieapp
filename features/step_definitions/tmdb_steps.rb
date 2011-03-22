require Rails.root + 'spec/support/fixtures'

World(FixtureLoader)

Given /^TMDB returns (?:nothing|"([^"]+)") for the terms "([^"]*)"$/ do |fixture, query|
  body = if fixture.blank?
    '["Nothing found."]'
  else
    read_fixture("tmdb-#{fixture}")
  end
  
  url = Tmdb::SEARCH_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :query => query
  
  stub_request(:get, url).to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})
  stub_request(:get, /api\.netflix\.com/).to_return(:body => '', :status => 200)
end

Given /^TMDB returns "([^"]+)" for (?:"([^"]+)" )?movie details$/ do |fixture, title|
  body = read_fixture("tmdb-#{fixture}")
  if title
    movie = find_movie title, :tmdb_id => {'$exists'=>true}
    url = Tmdb::DETAILS_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => movie.tmdb_id
  else
    url = %r{/Movie\.getInfo/}
  end
  
  stub_request(:get, url).to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})
end

Given /^the database contains movies from TMDB "([^"]+)"( with full info)?$/ do |fixture, has_info|
  body = read_fixture("tmdb-#{fixture}")
  Movie.from_tmdb_movies(Tmdb.parse(body).movies).each { |m| m.save }
  # hack: prevents ensure_extended_info from hitting the API
  Movie.collection.update({}, {'$unset' => {:tmdb_id => 1}}, :multi => true, :safe => true) if has_info
end