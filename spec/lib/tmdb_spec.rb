require 'spec_helper'
require 'tmdb'

describe Tmdb::Movie do
  
  result = Tmdb.parse read_fixture('tmdb-black_cat.json')
  
  subject { result.movies.first }
  
  its(:id)                { should == 1075 }
  its(:name)              { should == 'Black Cat, White Cat' }
  its(:alternative_name)  { should == 'Black Cat, White Cat' }
  its(:original_name)     { should == 'Crna mačka, beli mačor' }
  its(:imdb_id)           { should == 'tt0118843' }
  its(:url)               { should == 'http://www.themoviedb.org/movie/1075' }
  its(:synopsis)          { should include('Matko is a small time hustler') }
  its(:year)              { should == 1998 }
  its(:poster_cover) {
    should == 'http://hwcdn.themoviedb.org/posters/64f/4bf41d18017a3c320a00064f/crna-macka-beli-macor-cover.jpg'
  }
  
end
