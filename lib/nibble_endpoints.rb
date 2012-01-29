require 'faraday_middleware'
require 'nibbler/json'
require 'addressable/uri'
require 'addressable/template'

module NibbleEndpoints
  protected
  attr_reader :connection

  def define_connection(url_prefix, &block)
    @connection = Faraday::Connection.new(Addressable::URI.parse(url_prefix), &block)
  end

  def endpoint(name, url, parser = nil)
    template = Addressable::Template.new url.to_s
    parser ||= block_given? && Class.new(Nibbler, &Proc.new)
    endpoints[name.to_sym] = [template, parser]
  end

  def make_request(method, endpoint, params = {})
    template, parser = endpoints.fetch(endpoint.to_sym) {
      raise ArgumentError, "unknown endpoint #{endpoint.inspect}"
    }
    url = template.expand(params)
    response = connection.run_request(method, url, nil, nil) do |request|
      yield request if block_given?
    end

    if parser
      process_response(response, parser)
    else
      response
    end
  end

  def get(endpoint, params = {}, &block)
    make_request(:get, endpoint, params, &block)
  end

  private

  def endpoints
    @endpoints ||= {}
  end

  def process_response(response, parser)
    case response.status
    when 200
      data = response.body
      if content_type(response) =~ /\b(json|javascript)$/
        data = Nibbler::JsonDocument.new(data)
      end
      parser.parse(data)
    when 404
      nil
    else
      raise "got status #{response.status.inspect}"
    end
  end

  def content_type(response)
    response.headers['content-type'].to_s.split(';').first
  end
end
