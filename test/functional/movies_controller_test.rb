require 'test_helper'

class MoviesControllerTest < ActionController::TestCase
  
  test "listing movies" do
    get :index
    assert @response.success?
    assert_equal movies(:cabaret, :casablanca), assigns["movies"]
  end
  
end
