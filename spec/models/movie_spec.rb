require 'spec_helper'

describe Movie do
  before do
    Movie.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  it "detects existing movie from TMDB" do
    existing_id = collection.insert :tmdb_id => 1234
    tmdb_movie = Tmdb::Movie.new(nil)
    tmdb_movie.id = 1234
    tmdb_movie.name = "Where the Wild Things Are"
    
    movie = build(:tmdb_movie => tmdb_movie)
    movie.should be_persisted
    movie.id.should == existing_id
    movie.should be_changed
    movie.save
    movie.should match_selector(:title => "Where the Wild Things Are")
  end
  
  describe "extended info" do
    it "movie with complete info" do
      movie = Movie.create :runtime => 95, :countries => [], :directors => [], :homepage => "", :tmdb_id => 1234
      attributes = movie.to_hash
      movie.ensure_extended_info
      attributes.should == movie
    end
    
    it "movie with missing info fills the blanks" do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
        to_return(
          :body => read_fixture('tmdb-an_education.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )
      
      movie = Movie.create :tmdb_id => 1234
      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should_not == movie
      movie.runtime.should == 95
      movie.directors.should == ['Lone Scherfig']
    end
    
    it "movie with missing info but without a TMDB ID can't get details" do
      movie = Movie.create :directors => []
      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should == movie
      movie.directors.should == []
    end
  end
  
  describe "combined search" do
    before(:all) do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/star%20wars').
        to_return(
          :body => read_fixture('tmdb-star_wars-titles.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )
      stub_request(:get, 'api.netflix.com/catalog/titles?start_index=0&term=star%20wars&max_results=5&expand=synopsis').
        to_return(:body => read_fixture('netflix-star_wars-titles.xml'), :status => 200)
      
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
    
    it "should have IDs both from Netflix and TMDB" do
      @movies.map { |m| [m.tmdb_id, m.netflix_id] }.should == [
        [2004, 1001],
        [2003, 1002],
        [2002, 1005],
        [2001, nil],
        [2005, nil]
      ]
    end
  end
end