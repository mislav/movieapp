# encoding: utf-8
require 'spec_helper'
require 'tmdb'

describe Tmdb::Movie do

  context "normal one" do
    let(:result) {
      stub_request 'black cat', 'black_cat'
      Tmdb.search 'black cat'
    }

    subject {
      result.movies.first
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
    let(:result) {
      stub_request 'the terminator', 'terminator'
      Tmdb.search 'the terminator'
    }
    let(:movies) { result.movies }

    it "includes The Terminal" do
      movies.first.name.should == "The Terminal"
    end

    it "should not have duplicate original name" do
      terminator = movies.find { |m| m.name == 'The Terminator' }
      terminator.original_name.should be_nil
    end
    
    it "should erase synopsis if no overview" do
      no_overview = movies.find { |m| m.name == 'The Terminal Man' }
      no_overview.synopsis.should be_nil
    end
  end  

  it "can ignore a specific movie" do
    Tmdb.ignore_ids << 594
    begin
      stub_request 'the terminator', 'terminator'
      results = Tmdb.search 'the terminator'
      results.movies.should_not be_empty
      results.movies.map(&:name).should_not include("The Terminal")
    ensure
      Tmdb.ignore_ids.delete 594
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
      to_return(:body => fixture_body, :status => 200, :headers => {'content-type' => 'application/json'})
  end
  
end
