require 'spec_helper'

describe Movie do
  before do
    Movie.collection.remove
  end
  
  def collection
    described_class.collection
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
        to_return(:body => read_fixture('tmdb-an_education.json'), :status => 200)
      
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
end