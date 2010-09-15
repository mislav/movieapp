require 'spec_helper'
require 'netflix'

describe Netflix::Title do

  before(:all) do
    stub_request(:get, 'http://api.netflix.com/catalog/titles?start_index=0&term=mar%20adentro&max_results=5').
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

end

describe Netflix::Autocomplete do

  before(:all) do
    stub_request(:get, 'http://api.netflix.com/catalog/titles/autocomplete?term=step').
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
