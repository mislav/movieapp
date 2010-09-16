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

Given /^TMDB returns "([^"]+)" for "([^"]+)" movie details$/ do |fixture, title|
  body = read_fixture("tmdb-#{fixture}")
  movie = find_movie title, :tmdb_id => {'$exists'=>true}
  
  url = Tmdb::DETAILS_URL.expand :api_key => Movies::Application.config.tmdb.api_key, :tmdb_id => movie.tmdb_id
  
  stub_request(:get, url).to_return(:body => body, :status => 200)
end

Given /^the database contains movies from TMDB "([^"]+)"$/ do |fixture|
  body = read_fixture("tmdb-#{fixture}")
  Movie.from_tmdb_movies(Tmdb.parse(body).movies).each { |m| m.save }
end