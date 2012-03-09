# encoding: utf-8
require 'spec_helper'
require 'tmdb'

describe Tmdb::Configuration do

  subject {
    described_class.parse config_data
  }
  
  let(:config_data) {
    { "images" =>
      {"base_url" => "http://cf2.imgobject.com/t/p/",
       "poster_sizes" => available_sizes,
      }
    }
  }
  
  let(:available_sizes) { ["w92", "w154", "w185", "w342", "w500", "original"] }
  
  let(:poster_path) { '/abc.jpg' }
  
  it "generates tiny poster URL" do
    subject.poster_url(90, poster_path).should == "http://cf2.imgobject.com/t/p/w92/abc.jpg"
  end
  
  it "generates medium poster URL" do
    subject.poster_url(185, poster_path).should == "http://cf2.imgobject.com/t/p/w185/abc.jpg"
  end
  
  it "generates original poster URL" do
    subject.poster_url(501, poster_path).should == "http://cf2.imgobject.com/t/p/original/abc.jpg"
  end
  
  context "no original size present" do
    let(:available_sizes) { ["w92", "w154", "w185", "w342", "w500"] }
    
    it "fails for big size without original" do
      expect {
        subject.poster_url(501, poster_path)
      }.to raise_error(StandardError, "no original size available")
    end
  end
  
end
