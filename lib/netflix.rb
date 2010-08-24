require 'active_support/memoizable'
require 'oauth/consumer'
require 'nibbler'
require 'addressable/template'

module Netflix

  SITE = 'http://api.netflix.com'

  SEARCH_URL = Addressable::Template.new \
    "#{SITE}/catalog/titles?{-join|&|term,max_results,start_index,expand}"

  AUTOCOMPLETE_URL = Addressable::Template.new \
    "#{SITE}/catalog/titles/autocomplete?{-join|&|term}"
  
  def self.search(query, page = 1, per_page = 5)
    offset = per_page * (page.to_i - 1)
    
    request_uri = SEARCH_URL.expand(
      :term => query, :expand => 'directors,cast,synopsis',
      :max_results => per_page, :start_index => offset
    ).request_uri
    
    response = oauth_client.request(:get, request_uri)
    parse response.body
  end
  
  def self.parse(xml)
    Catalog.parse(xml)
  end
  
  def self.autocomplete(name)
    response = oauth_client.request(:get, AUTOCOMPLETE_URL.expand(:term => name).request_uri)
    Autocomplete.parse response.body
  end

  class << self
    extend ActiveSupport::Memoizable

    def oauth_client
      config = Movies::Application.config.netflix
      OAuth::Consumer.new(config.consumer_key, config.secret, :site => SITE)
    end
    memoize :oauth_client
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

end
