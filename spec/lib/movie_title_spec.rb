# encoding: utf-8
require 'spec_helper'
require 'movie_title'

describe MovieTitle do
  describe ".normalize_title" do
    def process(string)
      described_class.normalize_title(string)
    end
    
    it "transliterates unicode chars" do
      process('Čćđéñøü').should == 'ccdenou'
    end
    
    it "normalizes roman numerals" do
      process('Star Bores episode iii: Unwatchable').should == 'star bores episode 3 unwatchable'
    end
    
    it "normalizes whitespace" do
      process('Star Wars - A New Hope').should == 'star wars a new hope'
    end
    
    it "strips away 'the's" do
      process('The Honor of the Men').should == 'honor of men'
    end
  end
  
  describe "comparing" do
    class Title < Struct.new(:name, :year)
      include MovieTitle
    end
    
    let(:wars)  { Title.new('Star Wars', 2005) }
    let(:wars2) { Title.new('star wars', 2005) }
    let(:bores) { Title.new('Star Bores', 2005) }
    let(:wars_wrong_year) { Title.new('star wars', 2004) }
    let(:wars_remake) { Title.new('star wars', 2012) }
    let(:the_wars) { Title.new('the star wars', 2005) }
    
    it "considers different names as different titles" do
      wars.should_not == bores
    end
    
    it "considers same names, years as same title" do
      wars.should == wars2
    end
    
    it "doesn't tolerate difference of 1 in year" do
      wars.should_not == wars_wrong_year
    end
    
    it "doesn't tolerate larger difference in year" do
      wars.should_not == wars_remake
    end
    
    it "ignores 'the' in front of the name" do
      wars.should == the_wars
    end
  end
end
