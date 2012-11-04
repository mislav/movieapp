# encoding: utf-8
require 'spec_helper'
require 'netflix'

describe Netflix::Title do

  before(:all) do
    stub_request(:get, 'http://api-public.netflix.com/catalog/titles?start_index=0&term=mar%20adentro&max_results=5&v=1.5').
      to_return(:body => read_fixture('netflix-mar_adentro.xml'), :status => 200)
    
    @catalog = Netflix.search('mar adentro')
  end

  subject {
    @catalog.titles.first
  }

  its(:id)            { should == 70018295 }
  its(:url)           { should == 'http://www.netflix.com/Movie/The_Sea_Inside/70018295' }
  its(:name)          { should == 'The Sea Inside' }
  its(:poster_medium) { should == 'http://cdn-5.nflximg.com/us/boxshots/small/70018295.jpg' }
  its(:year)          { should == 2004 }
  its(:runtime)       { should == 125 }
  its(:directors)     { should == ["Alejandro Amenábar"] }
  its(:cast)          { should == ["Javier Bardem", "Belén Rueda", "Lola Dueñas"] }
  its(:official_url)  { should == 'http://www.mar-adentro.com/' }
  its(:synopsis)      { should include("this moving film based on a true story as Ramon Sampedro") }

  its(:special_edition?) { should be_false }

  it "detects special editions" do
    movie = subject.dup
    movie.name = "Mar Adentro: Special Edition"
    movie.name.should == 'Mar Adentro'
    movie.should be_special_edition
    movie.name = "Mar Adentro: Collector's Edition"
    movie.name.should == 'Mar Adentro'
    movie.should be_special_edition
  end

  it "strips away 'Unrated'" do
    movie = subject.dup
    movie.name = "Unrated Dirtiness"
    movie.name.should == "Unrated Dirtiness"
    movie.name = "Dirty Movie: Unrated"
    movie.name.should == "Dirty Movie"
    movie.should_not be_special_edition
  end

  it "strips away 'The Movie'" do
    movie = subject.dup
    movie.name = "The Movie About Tings"
    movie.name.should == "The Movie About Tings"
    movie.name = "Minesweeper: The Movie"
    movie.name.should == "Minesweeper"
    movie.should_not be_special_edition
  end
end

describe Netflix, "autocomplete" do

  before(:all) do
    stub_request(:get, 'http://api-public.netflix.com/catalog/titles/autocomplete?term=step&v=1.5').
      to_return(:body => read_fixture('netflix-autocomplete.xml'), :status => 200)
    
    @result = Netflix.autocomplete('step')
  end

  subject {
    @result.titles
  }

  its(:size)  { should == 10 }
  its(:first) { should == "Step Brothers" }
  its(:last)  { should == "The Stepford Wives" }

end
