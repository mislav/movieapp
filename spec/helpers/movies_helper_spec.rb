require 'spec_helper'

describe MoviesHelper do
  
  describe '#title_for_movie' do
    it "displays title" do
      movie = Movie.new :title => 'An Andalusian Dog'
      title_for_movie(movie).should == 'An Andalusian Dog'
    end
  
    it "includes original title if present" do
      movie = Movie.new :title => 'An Andalusian Dog', :original_title => 'Un chien andalou'
      title_for_movie(movie).should == '<i>Un chien andalou</i> / An Andalusian Dog'
    end
  end
  
end
