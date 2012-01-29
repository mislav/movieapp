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

Given /^there are three movies by Lone Scherfig$/ do
  movie = Movie.from_tmdb_movies(movies_from_tmdb_fixture('an_education.json')).first
  movie.save
  movie2 = Movie.create movie.to_hash.except('_id').update('title' => 'Another Lone Scherfig movie', 'year' => 2008)
  movie3 = Movie.create movie.to_hash.except('_id').update('title' => 'His third movie', 'year' => 2010)

  cond = {:directors => 'Lone Scherfig'}
  Movie.collection.update(cond, '$set' => {rotten_tomatoes: {updated_at: 5.minutes.ago.utc}})
  Movie.find(cond).count.should == 3
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
