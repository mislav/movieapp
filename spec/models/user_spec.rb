require 'spec_helper'

describe User do
  before do
    [User, Movie].each { |model| model.collection.remove }
  end
  
  def collection
    described_class.collection
  end
  
  it "has assignable username" do
    user = build :username => 'mislav'
    user.username.should == 'mislav'
  end
  
  it "cannot take an existing username" do
    collection.insert :username => 'mislav'
    
    user = build :username => 'mislav'
    user.username.should == 'mislav1'
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
          subject.watched.add_with_rating @deep_blue, true
          subject.watched.should include(@deep_blue)
          should match_selector('watched.movie' => @deep_blue.id, 'watched.liked' => true)
        end
        
        it "saves a watched movie with string rating" do
          subject.watched.add_with_rating @deep_blue, 'Yes'
          subject.watched.add_with_rating @breakfast, 'No'
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
        :twitter => { :screen_name => 'mislav', :name => 'Oldie Mislav' }
      
      user = User.from_twitter(@twitter_data)
      user.id.should == existing_id
      user.name.should == 'Mislav'
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
end