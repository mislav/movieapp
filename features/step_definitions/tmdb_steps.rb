require Rails.root + 'spec/support/fixtures'

World(FixtureLoader)

module TmdbFixtures
  def movies_from_tmdb_fixture(fixture)
    body = read_fixture("tmdb-#{fixture}")
    stub_request(:get, /api.themoviedb.org/).
      to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})

    Tmdb.search('').movies
  end
end

World(TmdbFixtures)

Given /^TMDB returns (?:nothing|"([^"]+)") for the terms "([^"]*)"$/ do |fixture, query|
  body = if fixture.blank?
    '["Nothing found."]'
  else
    read_fixture("tmdb-#{fixture}")
  end
  
  url = "api.themoviedb.org/2.1/Movie.search/en/json/TEST/#{query.gsub(' ', '%20')}"
  
  stub_request(:get, url).to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})
  stub_request(:get, /api\.netflix\.com/).to_return(:body => '', :status => 200)
end

Given /^TMDB returns "([^"]+)" for (?:"([^"]+)" )?movie details$/ do |fixture, title|
  body = read_fixture("tmdb-#{fixture}")
  if title
    movie = find_movie title, :tmdb_id => {'$exists'=>true}
    url = "api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/#{movie.tmdb_id}"
  else
    url = %r{/Movie\.getInfo/}
  end
  
  stub_request(:get, url).to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})
end

Given /^the database contains movies from TMDB "([^"]+)"( with full info)?$/ do |fixture, has_info|
  Movie.from_tmdb_movies(movies_from_tmdb_fixture(fixture)).each { |m| m.save }
  # hack: prevents ensure_extended_info from hitting the API
  Movie.collection.update({}, {'$unset' => {:tmdb_id => 1}}, :multi => true, :safe => true) if has_info
end

Given /^these movies are last watched$/ do
  watched = User.collection['watched']
  Movie.collection.find({}, :sort => [:_id, :desc]).limit(10).to_a.reverse.each do |movie_doc|
    watched.save 'movie_id' => movie_doc['_id']
  end
end
