require 'addressable/uri'
require 'net/http'
require 'yajl'

module Wikipedia
  SearchUrl = Addressable::URI.parse 'http://en.wikipedia.org/w/api.php?format=json&action=query&list=search'
  
  def self.search(query)
    url = SearchUrl.dup
    url.query_values = url.query_values.update :srsearch => query
    response = Net::HTTP.start(url.host, url.port) { |http|
      http.get url.request_uri, 'User-agent' => 'Movi.im <mislav.marohnic@gmail.com>'
    }
    response.error! unless Net::HTTPSuccess === response
    data = Yajl::Parser.parse response.body
    data['query']['search']
  end
  
  def self.find_title(query)
    result = search(query).first
    result['title'] if result
  end
end
