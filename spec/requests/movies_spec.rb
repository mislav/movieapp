require 'spec_helper'

describe "Movies" do
  describe "GET /[movie]/wikipedia" do
    before do
      @movie = Movie.create title: 'Misery', year: 1990
    end

    it "fetches wikipedia URL from its API" do
      stub_request(:get, 'en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=Misery%201990').
        to_return(
          body: {query: {search:[{title: 'Misery (1990 film)'}]}}.to_json,
          status: 200,
          headers: {'content-type' => 'application/json'}
        )

      get wikipedia_movie_path(@movie)
      response.status.should be(301)
      response.should redirect_to 'http://en.wikipedia.org/wiki/Misery_(1990_film)'
    end

    it "handles movie not found" do
      stub_request(:get, 'en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=Misery%201990').
        to_return(
          body: {query: {search:[]}}.to_json,
          status: 200,
          headers: {'content-type' => 'application/json'}
        )

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
