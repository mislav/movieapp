require 'faraday_middleware'

module Wikipedia
  def self.client
    @client ||= Faraday.new('https://en.wikipedia.org/w/api.php?format=json') do |client|
      if user_agent = Movies::Application.config.user_agent
        client.headers[:user_agent] = Movies::Application.config.user_agent
      end

      client.response :json
      client.use      :instrumentation
      client.response :raise_error
      client.adapter  :net_http
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
