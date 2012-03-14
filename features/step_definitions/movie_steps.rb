When /^I search for "([^"]*)"$/ do |query|
  When %(I fill in "#{query}" for "q")
  When %(I press "search")
end

When /^(.+) for the movie "([^"]+)"$/ do |step, title|
  @last_movie_title = title
  within ".movie:has(h1 a:contains('#{title}'))" do
    When step
  end
end

When /^(.+) for that movie$/ do |step|
  raise "no last movie" if @last_movie_title.blank?
  When %(#{step} for the movie "#{@last_movie_title}")
end

Given /^these movies by (.+?) exist:$/ do |director, movie_table|
  tmdb_id = 1000
  movies = movie_table.hashes.map do |movie_data|
    Movie.create({tmdb_id: (tmdb_id += 1)}.update(movie_data))
  end
  stub_extended_info(movies, directors: [director])
end

Then /^I should see movies: (.+)$/ do |movies|
  titles = movies.scan(/"([^"]+ \(\d+\))"/).flatten
  raise ArgumentError if titles.empty?

  found = all('.movie h1').zip(all('.movie .year time')).map { |pair| "#{pair.first.text.strip} (#{pair.last.text.strip})" }
  found.should =~ titles
end

Given /^(@.+) watched "([^"]+)"$/ do |users, title|
  movie = find_movie(title)
  @last_movie_title = movie.title
  
  each_user(users) do |user|
    user.watched << movie
  end
end

Given /^the database contains movies( with full info)? from searching for "([^"]+)"$/ do |has_info, search_term|
  movies = Movie.search(search_term)
  stub_extended_info(movies) if has_info
end

Given /^these movies are last watched by @(\w+)$/ do |username|
  user = find_or_create_user username
  watched = User.collection['watched']
  Movie.collection.find({}, :sort => [:_id, :asc]).limit(10).to_a.reverse.each do |movie_doc|
    watched.save 'movie_id' => movie_doc['_id'], 'user_id' => user.id
  end
end
