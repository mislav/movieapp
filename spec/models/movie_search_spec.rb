require 'spec_helper'

describe Movie do
  before do
    Movie.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  describe "combined search" do
    before(:all) do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/star%20wars').
        to_return(
          :body => read_fixture('tmdb-star_wars-titles.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )
      
      stub_request(:get, 'api.netflix.com/catalog/titles?start_index=0&term=star%20wars&max_results=5&expand=synopsis,directors').
        to_return(:body => read_fixture('netflix-star_wars-titles.xml'), :status => 200)

      stub_request(:get, 'api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=TOMATO&page=1&page_limit=5&q=star%20wars').
        to_return(
          :body => read_fixture('tomatoes-star_wars.json'),
          :status => 200,
          :headers => {'content-type' => 'text/javascript'}
        )
      
      @movies = Movie.search 'star wars'
    end
    
    it "should have ordering from Netflix" do
      @movies.map { |m| "#{m.title} (#{m.year})" }.should == [
        'Star Wars Episode 4 (1990)',
        'Star Wars Episode 5 (1991)',
        'Star Wars: Episode 1 (1993)',
        'Star Wars: The Making Of (2004)',
        'Star Wars Episode VI (1982)'
      ]
    end
    
    it "should have IDs from Netflix, TMDB, Rotten Tomatoes" do
      @movies.map { |m| [m.tmdb_id, m.netflix_id, m.rotten_id] }.should == [
        [2004, 1001, "11292"],
        [2003, 1002, nil],
        [2002, 1005, nil],
        [2001, nil,  nil],
        [2005, nil,  nil]
      ]
    end
  end

  it "handles failed TMDB search" do
    ep_one_id   = collection.insert title: 'Star Wars episode one', netflix_id: 1005
    new_hope_id = collection.insert title: 'Star Wars: A New Hope', netflix_id: 1001

    stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/star%20wars').to_return(status: 503)

    stub_request(:get, 'api.netflix.com/catalog/titles?start_index=0&term=star%20wars&max_results=5&expand=synopsis,directors').
      to_return(:body => read_fixture('netflix-star_wars-titles.xml'), :status => 200)

    movies = Movie.search 'star wars'
    movies.size.should == 2

    movies.first.id.should == new_hope_id
    movies.first.year.should == 1990

    movies.second.id.should == ep_one_id
    movies.second.year.should == 1993
  end

  it "falls back to regexp search" do
    collection.insert title: 'Unrelated Movie'
    collection.insert title: 'Star Wars episode one'
    collection.insert title: 'Star Wars: A New Hope'

    stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/star%20wars').to_return(status: 503)

    stub_request(:get, 'api.netflix.com/catalog/titles?start_index=0&term=star%20wars&max_results=5&expand=synopsis,directors').
      to_raise(Timeout::Error)

    movies = Movie.search 'star wars'
    movies.map(&:title).should == ['Star Wars episode one', 'Star Wars: A New Hope']
  end
end
