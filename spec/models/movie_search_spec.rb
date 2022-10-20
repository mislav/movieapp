require 'spec_helper'

describe Movie do

  before do
    Movie.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  describe "combined search", vcr: { cassette_name: 'movie_search/combined', record: :none } do

    before(:each) do
      @movies = Movie.search 'star wars'
    end
    
    it "should have ordering from Netflix" do
      @movies.map { |m| "#{m.title} (#{m.year})" }.should == [
        'Star Wars: Episode I - The Phantom Menace (1999)',
        'Star Wars: Episode V - The Empire Strikes Back (1980)',
        'Star Wars: Episode VI - Return of the Jedi (1983)',
        'Star Wars: Episode II - Attack of the Clones (2002)',
        'Star Wars: Episode III - Revenge of the Sith (2005)',
        'Star Wars: Episode IV - A New Hope (1977)',
        'Star Wars: The Clone Wars (2008)'
      ]
    end
    
    it "should have IDs from Netflix, TMDB, Rotten Tomatoes" do
      @movies.map { |m| [m.tmdb_id, m.netflix_id, m.rotten_id] }.should == [
        [1893,  nil, "star_wars_episode_i_the_phantom_menace"],
        [1891,  nil, "empire_strikes_back"],
        [1892,  nil, "star_wars_episode_vi_return_of_the_jedi"],
        [1894,  nil, "star_wars_episode_ii_attack_of_the_clones"],
        [1895,  nil, "star_wars_episode_iii_revenge_of_the_sith"],
        [11,    nil, "star_wars"],
        [12180, nil, "clone_wars"]
      ]
    end
  end

  describe "failed TMDB search", vcr: { cassette_name: 'movie_search/tmdb_fail', record: :none } do
    it "uses Netflix to find existing entries in the db" do
      ep_iii_id   = collection.insert title: 'Star Wars III', netflix_id: 70018728
      new_hope_id = collection.insert title: 'Star Wars IV', netflix_id: 60010932

      movies = Movie.search('star wars').to_a
      movies.size.should == 2

      movies[0].id.should == ep_iii_id
      movies[1].id.should == new_hope_id
    end
  end

  describe "failed TMDB and Netflix search", vcr: { cassette_name: 'movie_search/tmdb_netflix_fail', record: :none } do
    it "falls back to regexp search" do
      collection.insert title: 'Unrelated Movie'
      collection.insert title: 'Star Wars episode one'
      collection.insert title: 'Star Wars: A New Hope'

      movies = Movie.search 'star wars'
      movies.map(&:title).should == ['Star Wars episode one', 'Star Wars: A New Hope']
    end
  end
end
