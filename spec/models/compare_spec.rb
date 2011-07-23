require 'spec_helper'

describe User::Compare do
  before do
    Movie.collection.remove
    User.collection.remove
  end
  
  let(:user1)   { User.create :username => 'first'  }
  let(:user2)   { User.create :username => 'second' }
  let(:compare) { described_class.new(user1, user2) }

  it "finds movies both want to watch" do
    white, red, blue, purple = (1..4).map { Movie.create }
    user1.to_watch << white << red << purple
    user2.to_watch << blue << purple << white
    
    compare.movies_to_watch.to_a =~ [white, purple]
  end
end