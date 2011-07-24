require 'spec_helper'

describe User::Compare do
  before do
    Movie.collection.remove
    User.collection.remove
  end
  
  let(:user1)   { User.create :username => 'first'  }
  let(:user2)   { User.create :username => 'second' }
  let(:compare) { described_class.new(user1, user2) }

  it "finds movies both want to watch" do
    white, red, blue, purple = (1..4).map { Movie.create }
    user1.to_watch << white << red << purple
    user2.to_watch << blue << purple << white
    
    compare.movies_to_watch.to_a =~ [white, purple]
  end

  it "finds favorite directors" do
    white  = movie_by_directors 'Tim Burton'
    red    = movie_by_directors 'Tim Burton', 'Quentin Tarantino'
    blue   = movie_by_directors 'Quentin Tarantino'
    purple = movie_by_directors 'Quentin Tarantino', 'Steven Spielberg'
    gray   = movie_by_directors 'Steven Spielberg', 'David Fincher'
    
    [white, red, blue, purple].each { |movie| user1.watched.rate_movie(movie, true) }
    user1.watched.rate_movie(gray, false)
    
    compare.fav_directors1.should == ['Quentin Tarantino', 'Tim Burton']
  end

  def movie_by_directors(*names)
    Movie.create { |m| m['directors'] = names }
  end
end