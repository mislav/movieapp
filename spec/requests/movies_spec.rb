require 'spec_helper'

describe "Movies" do
  describe "GET /[movie]/wikipedia", vcr: { cassette_name: :Wikipedia, record: :none } do

    before do
      @movie = Movie.create title: 'Misery', year: 1990
    end

    it "fetches wikipedia URL from its API" do
      get wikipedia_movie_path(@movie)
      response.status.should be(301)
      response.should redirect_to 'http://en.wikipedia.org/wiki/Misery_(film)'
    end

    it "handles movie not found" do
      @movie.title = 'Klogaboogaloo'
      @movie.save

      get wikipedia_movie_path(@movie)
      response.status.should be(404)
    end

    it "uses stored wikipedia URL" do
      @movie.wikipedia_title = 'http://en.wikipedia.org/wiki/Misery_(1990_film)'
      @movie.save

      get wikipedia_movie_path(@movie)
      response.status.should be(301)
      response.should redirect_to @movie.wikipedia_url
    end
  end
end
