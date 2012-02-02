require 'spec_helper'
require 'ostruct'

describe Movie do
  before do
    Movie.collection.remove
    User.collection.remove
  end
  
  def collection
    described_class.collection
  end
  
  it "last watched" do
    user1 = user_create
    user2 = user_create
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
    let(:rotten_values) do
      {'updated_at' => 5.minutes.ago.utc}
    end

    it "movie with complete info" do
      movie = Movie.create :runtime => 95, :tmdb_id => 1234,
          :tmdb_updated_at => 1.day.ago.utc,
          :countries => [], :directors => [], :homepage => "" do |m|
        m['rotten_tomatoes'] = rotten_values
      end

      attributes = movie.to_hash
      movie.ensure_extended_info
      attributes.should == movie
    end

    it "movie with stale info" do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
        to_return(
          :body => read_fixture('tmdb-an_education.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )

      movie = Movie.create :runtime => 95, :tmdb_id => 1234,
          :tmdb_updated_at => 2.weeks.ago.utc,
          :countries => [], :directors => [], :homepage => "" do |m|
        m['rotten_tomatoes'] = rotten_values
      end

      movie.ensure_extended_info
      movie.tmdb_updated_at.should be_within(1).of(Time.now)
    end

    it "movie with missing info fills the blanks" do
      stub_request(:get, 'api.themoviedb.org/2.1/Movie.getInfo/en/json/TEST/1234').
        to_return(
          :body => read_fixture('tmdb-an_education.json'),
          :status => 200,
          :headers => {'content-type' => 'application/json'}
        )

      movie = Movie.create :tmdb_id => 1234 do |m|
        m['rotten_tomatoes'] = rotten_values
      end

      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should_not == movie
      movie.runtime.should == 95
      movie.directors.should == ['Lone Scherfig']
    end
    
    it "movie with missing info but without a TMDB ID can't get details" do
      movie = Movie.create :directors => [] do |m|
        m['rotten_tomatoes'] = rotten_values
      end

      attributes = movie.to_hash
      movie.ensure_extended_info
      movie.should_not be_changed
      attributes.should == movie
      movie.directors.should == []
    end
    
    it "has locked values" do
      tmdb = OpenStruct.new name: "Mr. Nobody", year: 2010
      netflix = OpenStruct.new title: "Mr Nobody", year: 2009

      movie = build tmdb_movie: tmdb
      movie['rotten_tomatoes'] = rotten_values

      movie.title.should == "Mr. Nobody"
      movie.year.should == 2010

      movie.netflix_title = netflix
      movie.title.should == "Mr. Nobody"
      movie.year.should == 2009

      movie.tmdb_movie = tmdb
      movie.year.should == 2009
    end

    it "refreshes Rotten info" do
      rotten_movie = OpenStruct.new \
        id: 369,
        genres: %w[Comedy Parody],
        url: 'http://www.rottentomatoes.com/m/a_movie/',
        critics_score: 98

      movie = build imdb_id: 'tt0123'
      movie.rotten_id.should be_nil
      movie.critics_score.should be_nil

      RottenTomatoes.should_receive(:find_by_imdb_id).once.with('tt0123').
        and_return(rotten_movie)

      movie.ensure_extended_info

      movie.rotten_id.should eq(369)
      movie.critics_score.should eq(98)
      movie.rotten_url.should eq('http://www.rottentomatoes.com/m/a_movie/')
      movie['rotten_tomatoes']['updated_at'].should be_within(1).of(Time.now)

      # do it again, checking nothing bad happens
      movie.ensure_extended_info
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
      Movie.create(tmdb_id: 1234) { |m| m.update_and_lock attributes }
    end
  end
  
  describe "wikipedia" do
    it "isn't linked to wikipedia" do
      movie = build
      movie.wikipedia_url.should be_nil
    end

    it "manually linked to wikipedia" do
      movie = build wikipedia_title: 'http://en.wikipedia.org/wiki/It_(1990_film)'
      movie.wikipedia_title.should == 'It_(1990_film)'
      movie.wikipedia_url.should == 'http://en.wikipedia.org/wiki/It_(1990_film)'
    end

    it "automatically linked to wikipedia" do
      stub_request(:get, 'en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=Misery%201990').
        to_return(
          body: {query: {search:[{title: 'Misery (1990 film)'}]}}.to_json,
          status: 200,
          headers: {'content-type' => 'application/json'}
        )

      movie = build title: 'Misery', year: 1990
      movie.update_wikipedia_url!
      movie.wikipedia_url.should == 'http://en.wikipedia.org/wiki/Misery_(1990_film)'
    end
  end
end
