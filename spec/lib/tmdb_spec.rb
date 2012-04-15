# encoding: utf-8
require 'spec_helper'
require 'tmdb'

describe Tmdb::Movie do

  use_vcr_cassette record: :none

  context "normal one" do
    let(:result) { Tmdb.search 'black cat' }

    subject { result.movies.first }

    its(:id)                { should == 1075 }
    its(:name)              { should == 'Black Cat, White Cat' }
    its(:original_name)     { should == 'Crna mačka, beli mačor' }
    its(:url)               { should == 'http://www.themoviedb.org/movie/1075' }
    its(:year)              { should == 1998 }
    its(:poster_cover) {
      should == 'http://cf2.imgobject.com/t/p/w185/7q96evV2xWjvkO4fMdqe8vixKb8.jpg'
    }
  end
  
  context "normal many" do
    let(:result) { Tmdb.search 'the terminator' }
    let(:movies) { result.movies }

    it "includes Terminator 2" do
      movies[1].name.should == "Terminator 2: Judgment Day"
    end

    it "should not have duplicate original name" do
      movies[1].original_name.should be_nil
    end
  end  

  context "blacklist" do
    before(:all) { Tmdb.ignore_ids << 534 }
    after(:all)  { Tmdb.ignore_ids.delete 534 }

    it "can ignore a specific movie" do
      results = Tmdb.search 'the terminator'
      results.movies.should_not be_empty
      results.movies.map(&:name).should_not include("Terminator: Salvation")
    end
  end

  context "empty" do
    subject { Tmdb.search('lepa brena') }
    its(:movies) { should be_empty }
  end
  
  describe "movie details" do
    subject { Tmdb.movie_details(24684) }

    its(:runtime) { should == 95 }
    its(:directors) { should == ["Lone Scherfig"] }
    its(:countries) { should == ["United Kingdom", "United States of America"] }
    its(:synopsis) { should include("teenage girl in 1960s suburban London") }
  end
  
end
