# encoding: utf-8
require 'spec_helper'
require 'ostruct'
require 'hashie/mash'

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
          lambda {
            subject.to_watch << @deep_blue
          }.should change(subject.to_watch, :total_entries)
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
          subject.to_watch.to_a.should == [@breakfast, @deep_blue]
        end
      
        it "doesn't add movie twice" do
          subject # trigger creating subject
          lambda { subject.to_watch << @deep_blue }.should_not change(join_collection, :size)
        end
      
        it "deletes a movie from watchlist" do
          lambda {
            subject.to_watch.delete @deep_blue
          }.should change(subject.to_watch, :total_entries).by(-1)
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
          subject.watched.rating_for(@deep_blue).should == true
          subject.watched.rating_for(@breakfast).should == false
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
          watched = subject.watched
          first, second = watched.to_a
          
          first.should == @deep_blue
          watched.rating_for(first).should == false
          
          second.should == @breakfast
          watched.rating_for(second).should == true
        end
        
        it "deletes a watched movie" do
          subject # trigger creating subject
          lambda { subject.watched.delete @deep_blue }.should change(join_collection, :size).by(-1)
          subject.watched.should_not include(@deep_blue)
          subject.watched.should include(@breakfast)
        end
      end
    end
  end
  
  describe ".login_from_provider" do
    before do
      @twitter_data = Hashie::Mash.new :screen_name => 'mislav', :name => 'Birdie Mislav', :id => 1234
      @facebook_data = Hashie::Mash.new :name => 'Private Mislav', :id => 2345
    end
    
    it "merges two user records" do
      existing_facebook_id = BSON::ObjectId.from_time(5.minutes.ago)
      collection.save :facebook => { :id => '2345' }, :_id => existing_facebook_id, :username => 'facebooker'
      existing_twitter_id = collection.insert :twitter => { :id => 1234 }, :username => 'twat'
      
      facebook_user = User.first existing_facebook_id
      facebook_user.watched << Movie.create
      facebook_user.watched << Movie.create
      facebook_user.to_watch << Movie.create
      
      twitter_user = User.first existing_twitter_id
      twitter_user.watched << Movie.create
      twitter_user.to_watch << Movie.create
      twitter_user.to_watch << Movie.create
      
      total_watched = twitter_user.watched.to_a + facebook_user.watched.to_a
      total_to_watch = twitter_user.to_watch.to_a + facebook_user.to_watch.to_a
      
      fb_auth = double(
        provider: 'facebook',
        uid: @facebook_data[:id],
        extra: double(raw_info: @facebook_data),
        credentials: nil
      )
      user = User.login_from_provider(fb_auth)
      user.id.should == existing_facebook_id
      expect(user.username).to eq('facebooker')

      tw_auth = double(
        provider: 'twitter',
        uid: @twitter_data[:id],
        extra: double(raw_info: @twitter_data),
        credentials: nil
      )
      user = User.login_from_provider(tw_auth, user)
      user.id.should == existing_facebook_id
      user['twitter']['id'].should == 1234
      expect(user.username).to eq('facebooker')
      
      user.watched.size.should == 3
      user.watched.to_a.should == total_watched
      user.to_watch.total_entries.should == 3
      user.to_watch.to_a.should == total_to_watch
      
      User.first(existing_twitter_id).should be_nil
    end

    it "generates a username from facebook ID" do
      user = User.new
      user.facebook_info = @facebook_data
      expect(user.username).to eq('fb-2345')
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
        user.twitter_friends = ["1234", 1235]
        user.facebook_friends = [2345, "2346"]
      }
    end
    
    it "connects over twitter and facebook" do
      @user.friends.map(&:id).should =~ @friends
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

    it "checks if following on twitter" do
      friend_id = @friends.first
      user2 = User.first(friend_id)
      @user.should be_following_on_twitter(user2)
      @user.should_not be_following_on_facebook(user2)
    end

    it "checks if following on facebook" do
      friend_id = @friends[1]
      user2 = User.first(friend_id)
      @user.should be_following_on_facebook(user2)
      @user.should_not be_following_on_twitter(user2)
    end
    
    it "checks if following directly" do
      user2 = create
      @user.add_friend(user2)
      @user.should_not be_following_on_facebook(user2)
      @user.should_not be_following_on_twitter(user2)
    end
  end

  describe "fetching friends lists" do
    let(:user) do
      build.tap { |user|
        user.twitter_friends = [234]
        user.facebook_friends = [234]
        user['twitter_token'] = ['TWTOKEN', 'TWSECRET']
      }
    end

    it "successful from twitter" do
      twitter_data = OpenStruct.new status: 200, ids: [1234, 4567]

      ServiceFetcher.should_receive(:get_twitter_friends).
        with(user['twitter_token']).
        and_return(twitter_data)

      user.fetch_twitter_friends
      user.twitter_friends.to_a.should =~ [1234, 4567]
      user['twitter_token'].should_not be_nil
    end

    it "failed from twitter" do
      twitter_data = OpenStruct.new status: 401

      ServiceFetcher.should_receive(:get_twitter_friends).
        with(user['twitter_token']).
        and_return(twitter_data)

      user.fetch_twitter_friends
      user.twitter_friends.to_a.should =~ [234]
      user['twitter_token'].should be_nil
    end
  end

  describe "picture" do
    let(:user) { build }

    it "has no picture" do
      user.picture_url.should be_nil
    end

    it "fetches picture from twitter" do
      user['twitter'] = {'id' => 1, 'screen_name' => 'mislav'}

      ServiceFetcher.should_receive(:get_twitter_profile_image).
        once.with('mislav').
        and_return('http:///mislav.png')

      user.picture_url.should eq('http:///mislav.png')
      user.reload.picture_url.should eq('http:///mislav.png')
    end

    it "refreshes stale twitter picture" do
      user['twitter'] = {'id' => 1, 'screen_name' => 'mislav'}
      user['twitter_picture'] = 'http:///mislav.png'
      user['twitter_picture_updated_at'] = 2.days.ago.utc

      ServiceFetcher.should_receive(:get_twitter_profile_image).
        once.with('mislav').
        and_return('http:///new_pic.png')

      user.picture_url.should eq('http:///new_pic.png')
    end

    it "uses facebook picture" do
      user['facebook'] = {'id' => '1'}
      user.picture_url.should eq('https://graph.facebook.com/1/picture?type=normal')
    end
  end
end
