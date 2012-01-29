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
  stub_extended_info({}) if has_info
end

Given /^these movies are last watched by @(\w+)$/ do |username|
  user = find_or_create_user username
  watched = User.collection['watched']
  Movie.collection.find({}, :sort => [:_id, :desc]).limit(10).to_a.reverse.each do |movie_doc|
    watched.save 'movie_id' => movie_doc['_id'], 'user_id' => user.id
  end
end

Given /^Rotten Tomatoes finds nothing by IMDB id$/ do
  url = %r{\bapi\.rottentomatoes\.com/.+/movie_alias\.json\b}
  stub_request(:get, url).to_return(status: 404)
end

Given /^Rotten Tomatoes returns empty search results$/ do
  url = %r{\bapi\.rottentomatoes\.com/.+/movies\.json\b}
  stub_request(:get, url).to_return(
    body: '{"movies": []}',
    status: 200,
    headers: {'content-type' => 'text/javascript'}
  )
end
