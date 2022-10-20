require 'spec_helper'
require 'mingo'

describe "Mingo User" do
  class User2 < Mingo
    property :name
    property :age
  
    def age=(value)
      super(value.nil? ? nil : value.to_i)
    end
  end

  def described_class
    User2
  end

  before :all do
    described_class.collection.remove
  end

  it "has connection" do
    Mingo.should be_connected
    described_class.should be_connected

    old_db = Mingo.db
    Mingo.db = nil
    begin
      Mingo.should_not be_connected
      described_class.should_not be_connected
      described_class.db.should be_nil
    ensure
      Mingo.db = old_db
    end
  end

  it "obtains an ID by saving" do
    user = build :name => 'Mislav'
    user.should_not be_persisted
    user.id.should be_nil
    user.save
    raw_doc(user.id)['name'].should == 'Mislav'
    user.should be_persisted
    user.id.should be_a(BSON::ObjectId)
  end
  
  it "tracks changes attribute" do
    user = build
    user.should_not be_changed
    user.name = 'Mislav'
    user.should be_changed
    user.changes.keys.should include(:name)
    user.name = 'Mislav2'
    user.changes[:name].should == [nil, 'Mislav2']
    user.save
    user.should_not be_changed
  end
  
  it "forgets changed attribute when reset to original value" do
    user = create :name => 'Mislav'
    user.name = 'Mislav2'
    user.should be_changed
    user.name = 'Mislav'
    user.should_not be_changed
  end
  
  it "has a human model name" do
    described_class.model_name.human.should == 'User2'
  end
  
  it "can reload values from the db" do
    user = create :name => 'Mislav'
    user.update '$unset' => {:name => 1}, '$set' => {:age => 26}
    user.age.should be_nil
    user.reload
    user.age.should == 26
    user.name.should be_nil
  end
  
  it "saves only changed values" do
    user = create :name => 'Mislav', :age => 26
    user.update '$inc' => {:age => 1}
    user.name = 'Mislav2'
    user.save
    user.reload
    user.name.should == 'Mislav2'
    user.age.should == 27
  end
  
  it "unsets values set to nil" do
    user = create :name => 'Mislav', :age => 26
    user.age = nil
    user.save

    raw_doc(user.id).tap do |doc|
      doc.should_not have_key('age')
      doc.should have_key('name')
    end
  end

  it "supports overloading the setter method" do
    user = build
    user.age = '12'
    user.age.should == 12
  end
  
  context "existing doc" do
    before do
      @id = described_class.collection.insert :name => 'Mislav', :age => 26
    end
    
    it "finds a doc by string ID" do
      user = described_class.first(@id.to_s)
      user.id.should == @id
      user.name.should == 'Mislav'
      user.age.should == 26
    end
  
    it "is unchanged after loading" do
      user = described_class.first(@id)
      user.should_not be_changed
      user.age = 27
      user.should be_changed
      user.changes.keys.should == [:age]
    end
  
    it "doesn't get changed by an inspect" do
      user = described_class.first(@id)
      # triggers AS stringify_keys, which dups the Dash and writes to it,
      # which mutates the @changes hash from the original Dash
      user.inspect
      user.should_not be_changed
    end
  end
  
  it "returns nil for non-existing doc" do
    doc = described_class.first('nonexist' => 1)
    doc.should be_nil
  end
  
  it "compares with another record" do
    one = create :name => "One"
    two = create :name => "Two"
    one.should_not == two
    
    one_dup = described_class.first(one.id)
    one_dup.should == one
  end
  
  it "returns a custom cursor" do
    cursor = described_class.collection.find({})
    cursor.should respond_to(:empty?)
  end
  
  context "cursor reverse" do
    it "can't reverse no order" do
      lambda {
        described_class.find({}).reverse
      }.should raise_error(RuntimeError)
    end

    it "reverses simple order" do
      cursor = described_class.find({}, :sort => :name).reverse
      cursor.order.should == [[:name, -1]]
    end

    it "reverses simple desc order" do
      cursor = described_class.find({}, :sort => [:name, :desc]).reverse
      cursor.order.should == [[:name, 1]]
    end

    it "reverses simple nested desc order" do
      cursor = described_class.find({}, :sort => [[:name, :desc]]).reverse
      cursor.order.should == [[:name, 1]]
    end

    it "can't reverse complex order" do
      lambda {
        described_class.find({}, :sort => [[:name, :desc], [:other, :asc]]).reverse
      }.should raise_error(RuntimeError)
    end

    it "reverses find by ids" do
      cursor = described_class.find([1,3,5]).reverse
      cursor.selector.should == {:_id => {"$in" => [5,3,1]}}
    end
  end
  
  context "find by ids" do
    before :all do
      @docs = [create, create, create]
      @doc1, @doc2, @doc3 = *@docs
    end

    it "orders results by ids" do
      results = described_class.find([@doc3.id, @doc1.id, @doc2.id]).to_a
      results.should == [@doc3, @doc1, @doc2]
    end

    it "handles limit + skip" do
      cursor = described_class.find([@doc3.id, @doc1.id, @doc2.id]).limit(1).skip(2)
      cursor.to_a.should == [@doc2]
    end

    it "doesn't die when offset is out of bounds" do
      cursor = described_class.find([@doc3.id, @doc1.id, @doc2.id]).skip(4)
      cursor.to_a.should be_empty
    end

    it "returns correct count" do
      cursor = described_class.find([@doc3.id, @doc1.id, @doc2.id]).limit(1).skip(2)
      cursor.count.should == 3
    end

    it "works with empty ID list" do
      results = described_class.find([]).to_a
      results.should be_empty
    end

    it "works with nonexistent ID" do
      results = described_class.find([BSON::ObjectId.new]).to_a
      results.should be_empty
    end
  end

  context "cache_key" do
    it "has it" do
      build.cache_key.should == "user2s/new"
    end

    it "includes the ID if persisted" do
      user = create
      user.cache_key.should == "user2s/#{user.id}"
    end

    it "includes the timestamp if present" do
      user = create
      user['updated_at'] = Time.utc 2011, 12, 13, 14, 15, 16
      user.cache_key.should == "user2s/#{user.id}-20111213141516"
    end
  end

  def build(*args)
    described_class.new(*args)
  end
  
  def create(*args)
    described_class.create(*args)
  end
  
  def raw_doc(selector)
    described_class.first(selector, :transformer => nil)
  end
end
