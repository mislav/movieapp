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
