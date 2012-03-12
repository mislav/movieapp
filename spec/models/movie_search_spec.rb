require 'spec_helper'

describe Movie do

  before do
    Movie.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  describe "combined search" do

    use_vcr_cassette 'movie_search/combined', record: :none

    before(:each) do
      @movies = Movie.search 'star wars'
    end
    
    it "should have ordering from Netflix" do
      @movies.map { |m| "#{m.title} (#{m.year})" }.should == [
        'Star Wars: Episode IV - A New Hope (1977)',
        'Star Wars: Episode I - The Phantom Menace (1999)',
        'Star Wars: Episode III - Revenge of the Sith (2005)',
        'Star Wars: Episode II - Attack of the Clones (2002)',
        'Star Wars: Episode V - The Empire Strikes Back (1980)',
        'Star Wars: Episode VI - Return of the Jedi (1983)',
        'Star Wars: The Clone Wars (2008)'
      ]
    end
    
    it "should have IDs from Netflix, TMDB, Rotten Tomatoes" do
      @movies.map { |m| [m.tmdb_id, m.netflix_id, m.rotten_id] }.should == [
        [11,    60010932, "11292"],
        [1893,  70003791, nil],
        [1895,  70018728, "9"],
        [1894,  60001814, "10009"],
        [1891,  60011114, "11470"],
        [1892,  nil,      "11366"],
        [12180, nil,      nil]
      ]
    end
  end

  describe "failed TMDB search" do
    use_vcr_cassette 'movie_search/tmdb_fail', record: :none

    it "uses Netflix to find existing entries in the db" do
      ep_iii_id   = collection.insert title: 'Star Wars III', netflix_id: 70018728
      new_hope_id = collection.insert title: 'Star Wars IV', netflix_id: 60010932

      movies = Movie.search 'star wars'
      movies.size.should == 2

      movies.first.id.should == new_hope_id
      movies.first.year.should == 1977

      movies.second.id.should == ep_iii_id
      movies.second.year.should == 2005
    end
  end

  describe "failed TMDB and Netflix search" do
    use_vcr_cassette 'movie_search/tmdb_netflix_fail', record: :none

    it "falls back to regexp search" do
      collection.insert title: 'Unrelated Movie'
      collection.insert title: 'Star Wars episode one'
      collection.insert title: 'Star Wars: A New Hope'

      movies = Movie.search 'star wars'
      movies.map(&:title).should == ['Star Wars episode one', 'Star Wars: A New Hope']
    end
  end
end
