# encoding: utf-8
require 'spec_helper'

describe User do
  before do
    [User, Movie].each { |model| model.collection.remove }
    [User.collection['watched'], User.collection['to_watch']].each(&:remove)
  end
  
  def collection
    described_class.collection
  end

  def join_collection_create(user, doc)
    join_collection.save doc.merge('user_id' => user.id)
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
      let(:join_collection) { User.collection['to_watch'] }
      
      context "user without watchlist" do
        subject { create }
        
        it "is empty when nothing no watch" do
          subject.to_watch.should be_empty
        end
      
        it "assigns a new movie to watch" do
          subject.to_watch << @deep_blue
          should_not be_changed
          subject.to_watch.should include(@deep_blue)
        end
      end
      
      context "user with watchlist" do
        subject {
          create.tap do |user|
            join_collection_create(user, 'movie_id' => @deep_blue.id)
            join_collection_create(user, 'movie_id' => @breakfast.id)
          end
        }
      
        it "initializes with existing movies to watch" do
          subject.to_watch.to_a.should == [@deep_blue, @breakfast]
        end
      
        it "doesn't add movie twice" do
          subject # trigger creating subject
          lambda { subject.to_watch << @deep_blue }.should_not change(join_collection, :size)
          subject.to_watch.size.should == 2
        end
      
        it "deletes a movie from watchlist" do
          subject.to_watch.delete @deep_blue
          subject.to_watch.should_not include(@deep_blue)
          subject.to_watch.should include(@breakfast)
        end
        
        it "marks movie as watched and that removes it from watchlist" do
          subject.watched << @deep_blue
          subject.to_watch.should_not include(@deep_blue)
        end
      end
    end
    
    describe "#watched" do
      let(:join_collection) { User.collection['watched'] }
      
      context "user without watched movies" do
        subject { create }
        
        it "is empty when nothing watched" do
          subject.watched.should be_empty
        end
        
        it "saves a watched movie" do
          subject.watched << @deep_blue
          should_not be_changed
          subject.watched.should include(@deep_blue)
        end
        
        it "saves a watched movie with rating" do
          subject.watched.rate_movie @deep_blue, true
          subject.watched.should include(@deep_blue)
        end
        
        it "saves a watched movie with string rating" do
          subject.watched.rate_movie @deep_blue, 'Yes'
          subject.watched.rate_movie @breakfast, 'No'
          subject.watched.rating_for(@deep_blue).should be_true
          subject.watched.rating_for(@breakfast).should be_false
        end
        
        it "removes a watched movie" do
          subject.watched << @deep_blue
          lambda { subject.watched.delete @deep_blue }.should change(join_collection, :size).by(-1)
        end
      end
      
      context "user with watched movies" do
        subject {
          create.tap do |user|
            join_collection_create(user, 'movie_id' => @deep_blue.id, 'liked' => false, '_id' => BSON::ObjectId.from_time(5.days.ago))
            join_collection_create(user, 'movie_id' => @breakfast.id, 'liked' => true, '_id' => BSON::ObjectId.from_time(1.month.ago))
          end
        }
        
        it "doesn't add a movie twice" do
          subject # trigger creating subject
          lambda { subject.watched << @deep_blue }.should_not change(join_collection, :size)
          subject.watched.size.should == 2
        end
        
        it "watched movies with rating information" do
          first, second = subject.watched.to_a
          
          first.should == @breakfast
          first.liked.should == true
          first.time_added.should be_within(1).of(1.month.ago)
          
          second.should == @deep_blue
          second.liked.should == false
          second.time_added.should be_within(1).of(5.days.ago)
        end
        
        it "deletes a watched movie" do
          subject # trigger creating subject
          lambda { subject.watched.delete @deep_blue }.should change(join_collection, :size).by(-1)
          subject.watched.should_not include(@deep_blue)
          subject.watched.should include(@breakfast)
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
      
      facebook_user = User.first existing_facebook_id
      facebook_user.watched << Movie.create
      facebook_user.watched << Movie.create
      facebook_user.to_watch << Movie.create
      
      twitter_user = User.first existing_twitter_id
      twitter_user.watched << Movie.create
      twitter_user.to_watch << Movie.create
      twitter_user.to_watch << Movie.create
      
      total_watched = facebook_user.watched.to_a + twitter_user.watched.to_a
      total_to_watch = facebook_user.to_watch.to_a + twitter_user.to_watch.to_a
      
      user = User.login_from_twitter_or_facebook(@twitter_data, @facebook_data)
      user.id.should == existing_facebook_id
      user['twitter']['id'].should == 1234
      
      user.watched.size.should == 3
      user.watched.to_a.should == total_watched
      user.to_watch.size.should == 3
      user.to_watch.to_a.should == total_to_watch
      
      User.first(existing_twitter_id).should be_nil
    end
  end
  
  describe "friends" do
    before do
      @movie = Movie.create
      @friends = []
      @friends << collection.insert(:twitter => { :id => 1234 })
      
      @mate = create(:username => 'mate', :facebook_info => { 'id' => "2345" })
      @mate.watched << @movie
      @friends << @mate.id
      
      @user = build.tap { |user|
        user.twitter_friends = [1234, 1235]
        user.facebook_friends = ["2345", "2346"]
      }
    end
    
    it "connects over twitter and facebook" do
      @user.friends.map(&:id).should =~ @friends
    end
    
    it "filters by watched movie" do
      friends = @user.friends_who_watched(@movie).to_a
      friends.should == [@mate]
      friends.first.username.should == 'mate'
    end
    
    it "finds movies" do
      @user.movies_from_friends.to_a.should == [@movie]
    end
    
    it "adds an extra friend" do
      user1 = create
      user2 = create
      user1.should_not be_following(user2)

      user1.add_friend(user2)
      user1.should be_following(user2)
      user1.friends.to_a.should include(user2)
    end
    
    it "removes a friend" do
      user1 = create
      user2 = create

      user1.add_friend(user2)
      user1.should be_following(user2)

      user1.remove_friend(user2)
      user1.should_not be_following(user2)
      user1.friends.to_a.should_not include(user2)
    end

    it "removes a twitter friend" do
      friend_id = @friends.first
      user2 = User.first(friend_id)
      @user.should be_following(user2)

      @user.remove_friend(friend_id)
      @user.friends.to_a.should_not include(user2)
      @user.should_not be_following(user2)
    end
  end
end
