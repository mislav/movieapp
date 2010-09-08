require 'spec_helper'
require 'tmdb'

describe Tmdb::Movie do
  
  subject {
    stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/black%20cat').
      to_return(:body => read_fixture('tmdb-black_cat.json'), :status => 200)
    
    result = Tmdb.search('black cat')
    result.movies.first
  }
  
  its(:id)                { should == 1075 }
  its(:name)              { should == 'Black Cat, White Cat' }
  # its(:alternative_name)  { should == 'Black Cat, White Cat' }
  its(:original_name)     { should == 'Crna mačka, beli mačor' }
  its(:imdb_id)           { should == 'tt0118843' }
  its(:url)               { should == 'http://www.themoviedb.org/movie/1075' }
  its(:synopsis)          { should include('Matko is a small time hustler') }
  its(:year)              { should == 1998 }
  its(:poster_cover) {
    should == 'http://hwcdn.themoviedb.org/posters/64f/4bf41d18017a3c320a00064f/crna-macka-beli-macor-cover.jpg'
  }
  
end

describe Tmdb::Movie, "empty" do
  
  subject {
    stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/lepa%20brena').
      to_return(:body => '["Nothing found."]', :status => 200)
    
    result = Tmdb.search('lepa brena')
  }
  
  its(:movies) { should be_empty }
  
end

describe Tmdb::Movie, "getInfo" do
  
  subject {
    stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
      to_return(:body => read_fixture('tmdb-an_education.json'), :status => 200)
    
    Tmdb.movie_details(1234)
  }
  
  
  its(:runtime) { should == 95 }
  
end
