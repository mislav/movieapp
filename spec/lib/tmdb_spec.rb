require 'spec_helper'
require 'tmdb'

describe Tmdb::Movie do

  context "normal one" do
    before(:all) do
      stub_request 'black cat', 'black_cat'
      @result = Tmdb.search('black cat')
    end
  
    subject {
      @result.movies.first
    }

    its(:id)                { should == 1075 }
    its(:name)              { should == 'Black Cat, White Cat' }
    its(:original_name)     { should == 'Crna mačka, beli mačor' }
    its(:imdb_id)           { should == 'tt0118843' }
    its(:url)               { should == 'http://www.themoviedb.org/movie/1075' }
    its(:synopsis)          { should include('Matko is a small time hustler') }
    its(:year)              { should == 1998 }
    its(:version)           { should == 29 }
    its(:poster_cover) {
      should == 'http://hwcdn.themoviedb.org/posters/64f/4bf41d18017a3c320a00064f/crna-macka-beli-macor-cover.jpg'
    }
  end
  
  context "normal many" do
    before(:all) do
      stub_request 'the terminator', 'terminator'
      result = Tmdb.search('the terminator')
      @movies = result.movies
      @terminator = @movies.find { |m| m.name == 'The Terminator' }
      @no_overview = @movies.find { |m| m.name == 'The Terminal Man' }
    end
    
    it "should not have duplicate original name" do
      @terminator.original_name.should be_nil
    end
    
    it "should erase synopsis if no overview" do
      @no_overview.synopsis.should be_nil
    end
  end  
  
  context "empty" do
    before(:all) do
      stub_request 'lepa brena', '["Nothing found."]'
      @result = Tmdb.search('lepa brena')
    end
    
    subject { @result }

    its(:movies) { should be_empty }
  end
  
  describe "movie details" do
    before(:all) do
      stub_request 1234, 'an_education', 'getInfo'
      @details = Tmdb.movie_details(1234)
    end
    
    subject { @details }

    its(:runtime) { should == 95 }
    its(:directors) { should == ["Lone Scherfig"] }
    its(:countries) { should == ["United Kingdom"] }
  end
  
  def stub_request(query, fixture, method = 'search')
    fixture_body = begin
      read_fixture "tmdb-#{fixture}.json"
    rescue
      fixture
    end
    
    super(:get, "api.themoviedb.org/2.1/Movie.#{method}/en/json/TEST/" + query.to_s.gsub(' ', '%20')).
      to_return(:body => fixture_body, :status => 200)
  end
  
end
