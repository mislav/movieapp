require 'faraday_stack'

module Wikipedia
  def self.client
    @client ||= FaradayStack.build('http://en.wikipedia.org/w/api.php?format=json',
        :headers => {:user_agent => Movies::Application.config.user_agent}).tap do |conn|
      conn.builder.insert_before Faraday::Adapter::NetHttp, FaradayStack::Instrumentation
    end
  end
  
  def self.perform_search(query)
    client.get do |req|
      req.params[:action] = 'query'
      req.params[:list] = 'search'
      req.params[:srsearch] = query
    end
  end
  
  def self.search(query)
    response = perform_search(query)
    response.body['query']['search']
  end
  
  def self.find_title(query)
    result = search(query).first
    result['title'] if result
  end
end
