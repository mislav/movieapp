require 'spec_helper'

describe User do
  before do
    [User, Movie].each { |model| model.collection.remove }
  end
  
  def collection
    described_class.collection
  end
  
  context "username" do
    it "is assignable" do
      user = build :username => 'mislav'
      user.username.should == 'mislav'
    end
  
    it "cannot take existing" do
      collection.insert :username => 'mislav'
    
      user = build :username => 'mislav'
      user.username.should == 'mislav1'
    end
  
    it "cannot take route" do
      user = build :username => 'movies'
      user.username.should == 'movies1'
    end
  end
  
  context "movies" do
    before do
      @deep_blue = Movie.create :title => "Le Grand Bleu"
      @breakfast = Movie.create :title => "Breakfast at Tiffany's"
    end
    
    describe "#to_watch" do
      context "user without watchlist" do
        subject { create }
        
        it "is empty when nothing no watch" do
          subject.to_watch.should be_empty
        end
      
        it "assigns a new movie to watch" do
          subject.to_watch << @deep_blue
          should_not be_changed
          subject.to_watch.should include(@deep_blue)
          should match_selector(:to_watch => @deep_blue.id)
        end
      end
      
      context "user with watchlist" do
        subject {
          create.tap do |user|
            user.update '$addToSet' => {:to_watch => {'$each' => [@deep_blue.id, @breakfast.id]}}
            user.reload
          end
        }
      
        it "initializes with existing movies to watch" do
          subject.to_watch.to_a.should == [@deep_blue, @breakfast]
        end
      
        it "deletes a movie from watchlist" do
          subject.to_watch.delete @deep_blue
          subject.to_watch.should_not include(@deep_blue)
          subject.to_watch.should include(@breakfast)
          should_not match_selector(:to_watch => @deep_blue.id)
        end
        
        it "marks movie as watched and that removes it from watchlist" do
          subject.watched << @deep_blue
          subject.to_watch.should_not include(@deep_blue)
          should_not match_selector(:to_watch => @deep_blue.id)
        end
      
        it "serializes" do
          hash = subject.to_hash
          hash['to_watch'].should == [@deep_blue.id, @breakfast.id]
        end
      
        it "serializes after changes" do
          subject.to_watch.delete @breakfast
          hash = subject.to_hash
          hash['to_watch'].should == [@deep_blue.id]
        end
      end
    end
    
    describe "#watched" do
      context "user without watched movies" do
        subject { create }
        
        it "is empty when nothing watched" do
          subject.watched.should be_empty
        end
        
        it "saves a watched movie" do
          subject.watched << @deep_blue
          should_not be_changed
          subject.watched.should include(@deep_blue)
          should match_selector('watched.movie' => @deep_blue.id)
        end
        
        it "saves a watched movie with rating" do
          subject.watched.rate_movie @deep_blue, true
          subject.watched.should include(@deep_blue)
          should match_selector('watched.movie' => @deep_blue.id, 'watched.liked' => true)
        end
        
        it "saves a watched movie with string rating" do
          subject.watched.rate_movie @deep_blue, 'Yes'
          subject.watched.rate_movie @breakfast, 'No'
          should match_selector('watched.movie' => @deep_blue.id, 'watched.liked' => true)
          should match_selector('watched.movie' => @breakfast.id, 'watched.liked' => false)
        end
        
        it "removes a watched movie" do
          subject.watched << @deep_blue
          subject.watched.delete @deep_blue
          should_not match_selector('watched.movie' => @deep_blue.id)
        end
      end
      
      context "user with watched movies" do
        subject {
          create.tap do |user|
            user.update '$addToSet' => {:watched => {'$each' => [
                {:movie => @deep_blue.id, :liked => false, :time => 5.days.ago.utc},
                {:movie => @breakfast.id, :liked => true, :time => 1.month.ago.utc}
              ]}}
            user.reload
          end
        }
        
        it "watched movies with rating information" do
          first, second = subject.watched.to_a
          
          first.should == @deep_blue
          first.liked.should == false
          first.time_added.should be_close(5.days.ago, 1)
          
          second.should == @breakfast
          second.liked.should == true
          second.time_added.should be_close(1.month.ago, 1)
        end
        
        it "deletes a watched movie" do
          subject.watched.delete @deep_blue
          subject.watched.should_not include(@deep_blue)
          subject.watched.should include(@breakfast)
          should_not match_selector(:watched => {:movie => @deep_blue.id})
        end
        
        it "has liked filter" do
          movies = subject.watched.liked.to_a
          movies == [@breakfast]
          movies.first.should be_liked
        end
      end
    end
  end
  
  describe ".from_twitter" do
    before do
      @twitter_data = Hashie::Mash.new :screen_name => 'mislav', :name => 'Birdie Mislav', :id => 1234
    end
    
    it "creates a new record" do
      user = User.from_twitter(@twitter_data)
      user.should be_persisted
      user.username.should == 'mislav'
      user.name.should == 'Birdie Mislav'
      user['twitter']['id'].should == 1234
      user.should match_selector('twitter.id' => 1234)
    end
    
    it "finds an existing twitter user and updates twitter info" do
      existing_id = collection.insert :name => 'Mislav',
        :twitter => { :screen_name => 'mislav_old', :name => 'Oldie Mislav', :id => 1234 }
      
      user = User.from_twitter(@twitter_data)
      user.id.should == existing_id
      user.name.should == 'Mislav'
      user['twitter']['screen_name'].should == 'mislav'
      user['twitter']['name'].should == 'Birdie Mislav'
    end
    
    it "generates a unique username in case twitter name is taken" do
      existing_id = collection.insert :username => 'mislav',
        :twitter => { :screen_name => 'mislav_impersonator' }
      
      user = User.from_twitter(@twitter_data)
      user.id.should_not == existing_id
      user.username.should == 'mislav1'
    end
  end
  
  describe ".from_facebook" do
    before do
      @facebook_data = Hashie::Mash.new :link => 'http://facebook.com/mislav', :name => 'Private Mislav', :id => 2345
    end
    
    it "creates a new record" do
      user = User.from_facebook(@facebook_data)
      user.should be_persisted
      user.username.should == 'mislav'
      user.name.should == 'Private Mislav'
      user['facebook']['id'].should == 2345
      user.should match_selector('facebook.id' => 2345)
    end
    
    it "finds an existing twitter user and updates twitter info" do
      existing_id = collection.insert :name => 'Mislav',
        :facebook => { :name => 'Oldie Mislav', :id => 2345 }
      
      user = User.from_facebook(@facebook_data)
      user.id.should == existing_id
      user.name.should == 'Mislav'
      user['facebook']['name'].should == 'Private Mislav'
      user['facebook']['link'].should == 'http://facebook.com/mislav'
    end
  end
  
  describe ".from_twitter_or_facebook" do
    before do
      @twitter_data = Hashie::Mash.new :screen_name => 'mislav', :name => 'Birdie Mislav', :id => 1234
      @facebook_data = Hashie::Mash.new :link => 'http://facebook.com/mislav', :name => 'Private Mislav', :id => 2345
    end
    
    it "merges two user records" do
      existing_facebook_id = BSON::ObjectId.from_time(5.minutes.ago)
      collection.save :facebook => { :id => 2345 }, :_id => existing_facebook_id
      existing_twitter_id = collection.insert :twitter => { :id => 1234 }
        
      user = User.login_from_twitter_or_facebook(@twitter_data, @facebook_data)
      user.id.should == existing_facebook_id
      user['twitter']['id'].should == 1234
      
      User.first(existing_twitter_id).should be_nil
    end
  end
  
  describe "friends" do
    it do
      expected = []
      expected << collection.insert(:twitter => { :id => 1234 })
      expected << collection.insert(:facebook => { :id => 2345 })
      
      user = build.tap { |u|
        u['twitter_friends'] = [1234, 1235]
        u['facebook_friends'] = [2345, 2346]
      }
      
      user.friends.map(&:id) =~ expected
    end
  end
end