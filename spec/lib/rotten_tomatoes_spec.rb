# encoding: utf-8
require 'spec_helper'
require 'rotten_tomatoes'

describe RottenTomatoes::Movie do

  describe "movie details" do
    before(:all) do
      stub_movie_details 1234, 'toystory'
      @movie = RottenTomatoes.movie_details(1234)
    end

    subject { @movie }

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
      stub_request "movie_alias.json?id=0435761&type=imdb", 'toystory'
      movie = RottenTomatoes.find_by_imdb_id 'tt435761'
      movie.name.should == "Toy Story 3"
    end

    it "doesn't find a movie" do
      response = %({ "error": "Could not find a movie with the specified id" })
      stub_request "movie_alias.json?id=0435761&type=imdb", response, 404
      movie = RottenTomatoes.find_by_imdb_id 'tt435761'
      movie.should be_nil
    end
  end

  def stub_movie_details(movie_id, fixture)
    stub_request "movies/#{movie_id}.json", fixture
  end

  def stub_request(path, fixture, status = 200)
    fixture_body = begin
      read_fixture "tomatoes-#{fixture}.json"
    rescue
      fixture
    end

    url = 'api.rottentomatoes.com/api/public/v1.0/' + path
    url << (url.include?('?') ? '&' : '?') << 'apikey=TOMATO'

    super(:get, url).to_return(:body => fixture_body, :status => status, :headers => {'content-type' => 'application/json'})
  end

end
