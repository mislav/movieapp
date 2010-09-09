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
      movie = Movie.new :runtime => 95, :countries => [], :directors => [], :homepage => "", :tmdb_id => 1234
      movie.save
      movie.ensure_extended_info
      movie.should_not be_changed
    end
    
    it "movie with missing info" do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
        to_return(:body => read_fixture('tmdb-an_education.json'), :status => 200)
      
      movie = Movie.new :tmdb_id => 1234
      movie.save
      movie.ensure_extended_info
      movie.should_not be_changed
      movie.runtime.should == 95
      movie.directors.should == ['Lone Scherfig']
    end
    
    it "movie with missing info" do
      movie = Movie.new :directors => []
      movie.save
      movie.ensure_extended_info
      movie.should_not be_changed
      movie.directors.should == []
    end
  end
end