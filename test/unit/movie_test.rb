require 'test_helper'

class MovieTest < ActiveSupport::TestCase
  test "have title and year" do
    movie = build_movie(:year => 1892)
    assert movie.save
  end
  
  test "year failure" do
    movie = build_movie(:year => 1870)
    assert !movie.save
  end
  
  test "is directed" do
    movie = create_movie
    clint = add_role(movie, 'director', "Clint Eastwood")
    
    assert_equal clint, movie.director
  end
  
  test "has actors" do
    movie = create_movie
    clint = add_role(movie, 'actor', "Clint Eastwood")
    ashton = add_role(movie, 'actor', "Ashton Kutcher")
    
    assert_equal [clint, ashton], movie.actors
  end
  
  test "both actors and director are members" do
    movie = create_movie
    clint = add_role(movie, 'director', "Clint Eastwood")
    ashton = add_role(movie, 'actor', "Ashton Kutcher")
    
    assert_equal [clint, ashton], movie.members
  end
  
  def valid_movie_attributes
    {:title => "Casablanca", :year => 1892}
  end
  
  def build_movie(attributes = {})
    Movie.new valid_movie_attributes.update(attributes)
  end
  
  def create_movie(attributes = {})
    movie = build_movie(attributes)
    movie.save!
    movie
  end
  
  def add_role(movie, position, member_name)
    member = Member.create(:name => member_name)
    movie.roles.create :member => member, :position => position
    member
  end
end
