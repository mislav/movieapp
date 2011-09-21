require 'spec_helper'

describe Movie do
  before do
    Movie.collection.remove
    User.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  it "last watched" do
    user1 = User.create
    user2 = User.create
    movie1 = Movie.create
    movie2 = Movie.create
    movie3 = Movie.create
    
    user1.watched << movie2
    user2.watched << movie2
    user2.watched << movie3
    user1.watched << movie1
    
    Movie.last_watched.to_a.should == [movie1, movie3, movie2]
  end

  it "last watched timestamp" do
    watched = User.collection['watched']
    watched.remove
    Movie.last_watch_created_at.should be_nil

    t1 = 5.minutes.ago
    t2 = 10.minutes.ago
    watched.insert :_id => BSON::ObjectId.from_time(t1, unique: true)
    watched.insert :_id => BSON::ObjectId.from_time(t2, unique: true)

    Movie.last_watch_created_at.should be_within(1).of(t1)
  end

  it "remembers updated_at" do
    Movie.collection.save '_id' => BSON::ObjectId.from_time(5.minutes.ago)
    movie = Movie.first
    movie.updated_at.should be_within(1).of(5.minutes.ago)
    movie.title = "Tales of Database Timestamps"
    movie.save
    movie.reload
    movie.updated_at.should be_within(1).of(Time.now)
  end
  
  describe "extended info" do
    it "movie with complete info" do
      movie = Movie.create :runtime => 95, :countries => [], :directors => [], :homepage => "", :tmdb_id => 1234
      attributes = movie.to_hash
      movie.ensure_extended_info
      attributes.should == movie
    end
    
    it "movie with missing info fills the blanks" do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
        to_return(
          :body => read_fixture('tmdb-an_education.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )
      
      movie = Movie.create :tmdb_id => 1234
      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should_not == movie
      movie.runtime.should == 95
      movie.directors.should == ['Lone Scherfig']
    end
    
    it "movie with missing info but without a TMDB ID can't get details" do
      movie = Movie.create :directors => []
      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should == movie
      movie.directors.should == []
    end
  end
  
  describe "combined search" do
    before(:all) do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.search/en/json/TEST/star%20wars').
        to_return(
          :body => read_fixture('tmdb-star_wars-titles.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )
      
      stub_request(:get, 'api.netflix.com/catalog/titles?start_index=0&term=star%20wars&max_results=5&expand=synopsis,directors').
        to_return(:body => read_fixture('netflix-star_wars-titles.xml'), :status => 200)
      
      @movies = Movie.search 'star wars'
    end
    
    it "should have ordering from Netflix" do
      @movies.map { |m| "#{m.title} (#{m.year})" }.should == [
        'Star Wars Episode 4 (1990)',
        'Star Wars Episode 5 (1991)',
        'Star Wars: Episode 1 (1993)',
        'Star Wars: The Making Of (2004)',
        'Star Wars Episode VI (1982)'
      ]
    end
    
    it "should have IDs both from Netflix and TMDB" do
      @movies.map { |m| [m.tmdb_id, m.netflix_id] }.should == [
        [2004, 1001],
        [2003, 1002],
        [2002, 1005],
        [2001, nil],
        [2005, nil]
      ]
    end
  end

  describe "permalink" do
    it "doesn't generate without sufficient data" do
      movie = create title: "Children of Men", year: nil
      movie.permalink.should be_nil
      movie.to_param.should == movie.id.to_s
    end

    it "generates on create" do
      movie = create title: "The Terminal", year: 2004
      movie.permalink.should == "Terminal_(2004)"
      movie.to_param.should == movie.permalink
    end

    it "doesn't regenerate more than needed" do
      movie = create title: "Very Long Engagement", year: 2004
      movie.permalink.should == "Very_Long_Engagement_(2004)"
      movie.title = "A Very Long Engagement"
      movie.save
      movie.permalink.should == "Very_Long_Engagement_(2004)"
    end

    it "generates unique permalink" do
      movie = create title: "Super 8", year: 2011
      movie.permalink.should == "Super_8_(2011)"
      movie = create title: "Super 8", year: 2011
      movie.permalink.should == "Super_8_(2011)_2"
      movie = create title: "Super 8", year: 2011
      movie.permalink.should == "Super_8_(2011)_3"
    end

    def create(attributes)
      Movie.create({tmdb_id: 1234, netflix_id: 2345}.update(attributes))
    end
  end
end