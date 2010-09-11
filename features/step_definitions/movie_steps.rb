module MovieFinder
  def find_movie(title, options = {})
    Movie.first({:title => title}.update(options)).tap do |movie|
      raise "movie not found" unless movie
    end
  end
end

World(MovieFinder)

When /^I search for "([^"]*)"$/ do |query|
  When %(I fill in "#{query}" for "Movie search")
  When %(I press "search")
end

When /^(.+) for the movie "([^"]+)"$/ do |step, title|
  within ".movie:has(a h1:contains('#{title}'))" do
    Then step
  end
end

Given /^there are three movies by Lone Scherfig$/ do
  data = read_fixture 'tmdb-an_education.json'
  tmdb_movie = Tmdb.parse(data).movies.first
  movie = Movie.find_or_create_from_tmdb tmdb_movie
  movie2 = Movie.create movie.to_hash.except('_id').update(:title => 'Another Lone Scherfig movie', :year => 2008)
  movie3 = Movie.create movie.to_hash.except('_id').update(:title => 'His third movie', :year => 2010)
  
  Movie.find(:directors => 'Lone Scherfig').count.should == 3
end

Then /^I should see movies: (.+)$/ do |movies|
  values = movies.scan(/"([^"]+) \((\d+)\)"/)
  movie_titles = values.map(&:first)
  movie_years = values.map(&:last)
  
  movie_titles.should == all('.movie h1').map(&:text)
  movie_years.should == all('.movie .year time').map(&:text)
end
