# encoding: utf-8
require 'spec_helper'
require 'rotten_tomatoes'

describe RottenTomatoes::Movie do

  use_vcr_cassette 'RottenTomatoes_Movie', record: :none

  describe "movie details" do
    subject { RottenTomatoes.movie_details(770672122) }

    its(:id) { should eq('770672122') }
    its(:name) { should == "Toy Story 3" }
    its(:year) { should == 2010 }
    its(:critics_score) { should == 99 }
    its(:url) { should == "http://www.rottentomatoes.com/m/toy_story_3/" }
    its(:imdb_id) { should == 'tt0435761' }
    its(:genres) { should == ["Animation", "Kids & Family", "Science Fiction & Fantasy", "Comedy"] }
    its(:poster_thumbnail) { should == "http://content6.flixster.com/movie/11/13/43/11134356_mob.jpg" }
  end

  describe "by IMDB id" do
    it "finds a movie" do
      movie = RottenTomatoes.find_by_imdb_id 'tt435761'
      movie.name.should == "Toy Story 3"
    end

    it "doesn't find a movie" do
      movie = RottenTomatoes.find_by_imdb_id 'tt43576109999'
      movie.should be_nil
    end
  end

end
