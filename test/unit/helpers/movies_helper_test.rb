require 'test_helper'

class MoviesHelperTest < ActionView::TestCase
  
  test "title for movie" do
    movie = Movie.new :title => 'An Andalusian Dog'
    assert_equal 'An Andalusian Dog', title_for_movie(movie)
  end
  
  test "title for movie with original title" do
    movie = Movie.new :title => 'An Andalusian Dog', :original_title => 'Un chien andalou'
    assert_equal '<i>Un chien andalou</i> / An Andalusian Dog', title_for_movie(movie)
  end
  
end
