require 'oauth/consumer'
require 'cgi'
require 'nibbler'

module Netflix

  def self.client
    @client ||= OAuth::Consumer.new(
      $settings.netflix.consumer_key,
      $settings.netflix.secret,
      :site => 'http://api.netflix.com'
    )
  end
  
  class Title < Nibbler
    element 'id' => :id
    element './title/@regular' => :name
    element './box_art/@small' => :poster_small
    element './box_art/@medium' => :poster_medium
    element './box_art/@large' => :poster_large
    element 'release_year' => :year
    element 'runtime' => :runtime
    element 'synopsis' => :synopsis
    elements './link[@title="directors"]/people/link/@title' => :directors
    elements './link[@title="cast"]/people/link/@title' => :cast
    element './/link[@title="web page"]/@href' => :netflix_url
    element './/link[@title="official webpage"]/@href' => :official_url
  end
  
  class Catalog < Nibbler
    elements 'catalog_title' => :titles, :with => Title
    
    element 'number_of_results' => :total_entries
    element 'results_per_page' => :per_page
    element 'start_index' => :offset
  end
  
  class Autocomplete < Nibbler
    elements './/autocomplete_item/title/@short' => :titles
  end
  
  def self.search(name, page = 1, per_page = 5)
    offset = per_page * (page.to_i - 1)
    response = client.request(:get, "/catalog/titles?term=#{CGI.escape name}&max_results=#{per_page}&start_index=#{offset}&expand=directors,cast,synopsis")
    parse response.body
  end
  
  def self.parse(xml)
    Catalog.parse(xml)
  end
  
  def self.autocomplete(name)
    response = client.request(:get, "/catalog/titles/autocomplete?term=#{CGI.escape name}")
    Autocomplete.parse response.body
  end
end

if $0 == __FILE__
  require 'spec/autorun'
  
  describe Netflix::Title do
    
    CATALOG = Netflix.parse(DATA.read)
    
    subject { CATALOG.titles.first }
    
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
end

__END__
<catalog_titles>
<catalog_title>
    <id>http://api.netflix.com/catalog/titles/movies/70018295</id><title short="The Sea Inside" regular="The Sea Inside"/>
<box_art small="http://cdn-5.nflximg.com/us/boxshots/tiny/70018295.jpg" medium="http://cdn-5.nflximg.com/us/boxshots/small/70018295.jpg" large="http://cdn-5.nflximg.com/us/boxshots/large/70018295.jpg"/>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/synopsis" rel="http://schemas.netflix.com/catalog/titles/synopsis" title="synopsis"><synopsis><![CDATA[<a href="http://www.netflix.com/RoleDisplay/Javier_Bardem/20001338">Javier Bardem</a> stars in this moving film based on a true story as Ramon Sampedro, a Spaniard who's condemned to life as a quadriplegic. Determined to die with dignity, Sampedro leads a 30-year campaign to win the right to end his life. His extraordinary example even inspires his lawyer, Julia (<a href="http://www.netflix.com/RoleDisplay/Bel_n_Rueda/30009945">Belen Rueda</a>), and a local woman (<a href="http://www.netflix.com/RoleDisplay/Lola_Due_as/20042060">Lola Duenas</a>) to reach for the heavens, with both women achieving far beyond their wildest dreams.]]></synopsis></link>
<release_year>2004</release_year>
<category scheme="http://api.netflix.com/categories/mpaa_ratings" label="PG-13" term="PG-13"/>
<category scheme="http://api.netflix.com/categories/genres" label="Foreign" term="Foreign"/>
<category scheme="http://api.netflix.com/categories/genres" label="Foreign Dramas" term="Foreign Dramas"/>
<category scheme="http://api.netflix.com/categories/genres" label="Spain" term="Spain"/>
<category scheme="http://api.netflix.com/categories/genres" label="Foreign Must-See" term="Foreign Must-See"/>
<category scheme="http://api.netflix.com/categories/genres" label="Spanish Language" term="Spanish Language"/>
<category scheme="http://api.netflix.com/categories/genres" label="Foreign Languages" term="Foreign Languages"/>
<category scheme="http://api.netflix.com/categories/genres" label="Foreign Regions" term="Foreign Regions"/>
<category scheme="http://api.netflix.com/categories/genres" label="Warner Home Video" term="Warner Home Video"/>
<runtime>7500</runtime>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/awards" rel="http://schemas.netflix.com/catalog/titles/awards" title="awards"/>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/format_availability" rel="http://schemas.netflix.com/catalog/titles/format_availability" title="formats"/>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/screen_formats" rel="http://schemas.netflix.com/catalog/titles/screen_formats" title="screen formats"/>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/cast" rel="http://schemas.netflix.com/catalog/people.cast" title="cast"><people><link href="http://api.netflix.com/catalog/people/20001338" rel="http://schemas.netflix.com/catalog/person" title="Javier Bardem"/><link href="http://api.netflix.com/catalog/people/30009945" rel="http://schemas.netflix.com/catalog/person" title="Bel&#xE9;n Rueda"/><link href="http://api.netflix.com/catalog/people/20042060" rel="http://schemas.netflix.com/catalog/person" title="Lola Due&#xF1;as"/></people></link>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/directors" rel="http://schemas.netflix.com/catalog/people.directors" title="directors"><people><link href="http://api.netflix.com/catalog/people/20004974" rel="http://schemas.netflix.com/catalog/person" title="Alejandro Amen&#xE1;bar"/></people></link>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/languages_and_audio" rel="http://schemas.netflix.com/catalog/titles/languages_and_audio" title="languages and audio"/>
<average_rating>3.9</average_rating>
<link href="http://api.netflix.com/catalog/titles/movies/70018295/similars" rel="http://schemas.netflix.com/catalog/titles.similars" title="similars"/>
<link href="http://www.mar-adentro.com/" rel="http://schemas.netflix.com/catalog/titles/official_url" title="official webpage"/>
<link href="http://www.netflix.com/Movie/The_Sea_Inside/70018295" rel="alternate" title="web page"/>

  </catalog_title>
</catalog_titles>
