require 'test_helper'

class MovieTest < ActiveSupport::TestCase
  test "have title and year" do
    movie = Movie.new(:title => "Casablanca", :year => 1892)
    assert movie.save
  end
  
  test "year failure" do
    movie = Movie.new(:title => "Casablanca", :year => 1875)
    assert !movie.save
  end
end
