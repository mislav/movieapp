require 'active_support/memoizable'
require 'oauth/consumer'
require 'nibbler'
require 'addressable/template'

module Netflix

  SITE = 'http://api.netflix.com'

  SEARCH_URL = Addressable::Template.new \
    "#{SITE}/catalog/titles?{-join|&|term,max_results,start_index,expand}"

  AUTOCOMPLETE_URL = Addressable::Template.new \
    "#{SITE}/catalog/titles/autocomplete?term={term}"

  class << self
    extend ActiveSupport::Memoizable
  
    def search(query, options = {})
      response = perform_search(query, options)
      parse response.body
    end
    
    def perform_search(query, options = {})
      page = options[:page] || 1
      per_page = options[:per_page] || 5
      offset = per_page * (page.to_i - 1)

      params = {:term => query, :max_results => per_page, :start_index => offset}
      params[:expand] = options[:expand].join(',') if options[:expand]
      
      search_uri = SEARCH_URL.expand params

      oauth_client.request(:get, search_uri.request_uri)
    end
  
    def parse(xml)
      Catalog.parse(xml)
    end
  
    def autocomplete(name)
      response = perform_autocomplete(name)
      Autocomplete.parse response.body
    end
    
    def perform_autocomplete(name)
      autocomplete_uri = AUTOCOMPLETE_URL.expand(:term => name)
      oauth_client.request(:get, autocomplete_uri.request_uri)
    end

    def oauth_client
      config = Movies::Application.config.netflix
      OAuth::Consumer.new(config.consumer_key, config.secret, :site => SITE)
    end
    memoize :oauth_client
  end
  
  class Title < Nibbler
    element :id, :with => lambda { |url_node|
      url_node.text.scan(/\d+/).last.to_i
    }
    element './title/@regular' => :name
    element './box_art/@small' => :poster_small
    element './box_art/@medium' => :poster_medium
    element './box_art/@large' => :poster_large
    element 'release_year' => :year, :with => lambda { |node| node.text.to_i }
    element :runtime, :with => lambda { |node| node.text.to_i / 60 }
    element 'synopsis' => :synopsis
    elements './link[@title="directors"]/people/link/@title' => :directors
    elements './link[@title="cast"]/people/link/@title' => :cast
    element './/link[@title="web page"]/@href' => :url
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
