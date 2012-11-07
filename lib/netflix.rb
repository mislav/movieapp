require 'nibble_endpoints'
require 'failsafe_store'
require 'movie_title'
require 'nokogiri'

module Netflix
  extend NibbleEndpoints

  class ParseXml < Struct.new(:app)
    def call(env)
      app.call(env).on_complete do
        env[:body] = Nokogiri::XML env[:body]
      end
    end
  end

  define_connection 'http://api-public.netflix.com' do |conn|
    if user_agent = Movies::Application.config.user_agent
      conn.headers[:user_agent] = user_agent
    end

    # http://developer.netflix.com/docs/REST_API_Conventions#0_pgfId-1009147
    conn.params[:v] = '1.0'

    oauth_config = Movies::Application.config.netflix
    conn.request :oauth,
      :consumer_key => oauth_config.consumer_key,
      :consumer_secret => oauth_config.secret

    conn.use ParseXml

    if Movies::Application.config.api_caching
      conn.response :caching do
        FailsafeStore.new Rails.root + 'tmp/cache', :namespace => 'netflix', :expires_in => 1.day,
          :exceptions => ['Faraday::Error::ClientError']
      end
    end

    conn.use :instrumentation
    conn.response :raise_error
    conn.adapter :net_http
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

  endpoint(:search_titles, '/catalog/titles?{-join|&|term,max_results,start_index,expand}') do
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

    get(:search_titles, params)
  end

  endpoint(:title_details, '/catalog/titles/movies/{title_id}?{-join|&|expand}') do
    element 'catalog_title' => :title, :with => Title
  end

  def self.movie_info(movie_id, options = {})
    fields = Array(options.fetch(:expand, 'synopsis'))
    get(:title_details, title_id: movie_id, expand: fields.join(',')).title
  end

  endpoint(:autocomplete_titles, '/catalog/titles/autocomplete?term={term}') do
    elements './/autocomplete_item/title/@short' => :titles
  end

  def self.autocomplete(term)
    get(:autocomplete_titles, :term => term)
  end
end
