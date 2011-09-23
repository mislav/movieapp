require 'nibble_spec'
require 'faraday_middleware'
require 'failsafe_store'
require 'movie_title'

module Netflix
  extend NibbleSpec
  
  build_stack 'http://api.netflix.com'

  if user_agent = Movies::Application.config.user_agent
    faraday.headers[:user_agent] = user_agent
  end

  # instrumentation
  faraday.builder.insert_before Faraday::Adapter::NetHttp, FaradayStack::Instrumentation

  # OAuth
  config = Movies::Application.config.netflix
  faraday.builder.insert_before Faraday::Request::UrlEncoded, Faraday::Request::OAuth,
    :consumer_key => config.consumer_key, :consumer_secret => config.secret

  # caching
  if Movies::Application.config.api_caching
    faraday.builder.insert_before FaradayStack::ResponseJSON, FaradayStack::Caching do
      FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'netflix', :expires_in => 1.day,
        :exceptions => ['Faraday::Error::ClientError']
    end
  end

  class Title < Nibbler
    include MovieTitle
    
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
    
    def name=(value)
      if value.respond_to?(:sub)
        value = value.sub(/(\s*:)?\s+(the movie|unrated)$/i, '')
        @special_edition = !!value.sub!(/(\s*:)?\s+(special|collector's) edition$/i, '')
      end
      @name = value
    end
    
    def special_edition?
      @special_edition
    end
  end

  get(:search_titles, '/catalog/titles?{-join|&|term,max_results,start_index,expand}') do
    elements 'catalog_title' => :titles, :with => Title
    element 'number_of_results' => :total_entries
    element 'results_per_page' => :per_page
    element 'start_index' => :offset
  end

  def self.search(query, options = {})
    page = options[:page] || 1
    per_page = options[:per_page] || 5
    offset = per_page * (page.to_i - 1)
    
    params = {:term => query, :max_results => per_page, :start_index => offset}
    params[:expand] = Array(options[:expand]).join(',') if options[:expand]
    
    search_titles(params)
  end

  get(:title_details, '/catalog/titles/movies/{title_id}?{-join|&|expand}') do
    element 'catalog_title' => :title, :with => Title
  end

  def self.movie_info(movie_id, options = {})
    fields = Array(options.fetch(:expand, 'synopsis'))
    title_details(title_id: movie_id, expand: fields.join(',')).title
  end

  get(:autocomplete_titles, '/catalog/titles/autocomplete?term={term}') do
    elements './/autocomplete_item/title/@short' => :titles
  end

  def self.autocomplete(term)
    autocomplete_titles(:term => term)
  end
end
