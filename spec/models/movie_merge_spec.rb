require 'spec_helper'

describe Movie do
  before do
    Movie.collection.remove
    User.collection.remove
  end

  it "merges movies" do
    user1 = user_create
    user2 = user_create
    user3 = user_create
    movie1 = Movie.create imdb_id: 't1234', title: 'Ed Wood'
    movie2 = Movie.create imdb_id: 't2345', tmdb_id: 8888
    movie3 = Movie.create netflix_id: 1212
    movie4 = Movie.create wikipedia_title: 'Ed Wood (1994)'
    # untouched movies
    movie5 = Movie.create
    movie6 = Movie.create

    user1.watched.rate_movie(movie2, true)
    user1.watched.rate_movie(movie3, false)
    user1.to_watch << movie4
    user2.to_watch << movie2
    user2.to_watch << movie4

    user3.watched.rate_movie(movie5, true)
    user3.to_watch << movie6

    Movie.merge!(movie1.id.to_s, movie2.id.to_s, movie3.id.to_s, movie4.id.to_s)
    reload_user user1, user2, user3

    movies = Movie.find.sort(:_id).to_a
    movies.should == [movie1, movie5, movie6]
    movie = movies.first

    movie.title.should == 'Ed Wood'
    movie.imdb_id.should == 't1234'
    movie.tmdb_id.should == 8888
    movie.netflix_id.should == 1212
    movie.wikipedia_title.should == 'Ed Wood (1994)'

    user1['watched_count'].should == 1
    user1['to_watch_count'].should == 0
    user1.watched.should include(movie1)
    user1.watched.rating_for(movie1).should == true
    user1.to_watch.should_not include(movie1)

    user2['watched_count'].should == 0
    user2['to_watch_count'].should == 1
    user2.to_watch.should include(movie1)
    user2.watched.should_not include(movie1)

    user3.watched.should include(movie5)
    user3.watched.rating_for(movie5).should == true
    user3.to_watch.should include(movie6)
  end

  def reload_user(*users)
    users.each do |user|
      user.reload.watched.reload
      user.to_watch.reload
    end
  end
end
