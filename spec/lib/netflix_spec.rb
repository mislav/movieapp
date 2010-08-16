require 'spec_helper'
require 'netflix'

describe Netflix::Title do

  catalog = Netflix.parse read_fixture('netflix-mar_adentro.xml')

  subject { catalog.titles.first }

  its(:id)            { should == 'http://api.netflix.com/catalog/titles/movies/70018295' }
  its(:name)          { should == 'The Sea Inside' }
  its(:poster_medium) { should == 'http://cdn-5.nflximg.com/us/boxshots/small/70018295.jpg' }
  its(:year)          { should == '2004' }
  its(:runtime)       { should == '7500' }
  its(:directors)     { should == ["Alejandro Amenábar"] }
  its(:cast)          { should == ["Javier Bardem", "Belén Rueda", "Lola Dueñas"] }
  its(:official_url)  { should == 'http://www.mar-adentro.com/' }
  its(:synopsis)      { should include("this moving film based on a true story as Ramon Sampedro") }

end
