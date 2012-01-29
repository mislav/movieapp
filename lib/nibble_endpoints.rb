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

  def endpoints
    @endpoints ||= {}
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
    response = connection.run_request(method, template.expand(params), nil, nil) do |request|
      yield request if block_given?
    end

    if parser
      data = response.body
      type = response.headers['content-type'].to_s.split(';').first
      data = Nibbler::JsonDocument.new(data) if type =~ /\bjson$/
      parser.parse(data)
    else
      response.body
    end
  end

  def get(endpoint, params = {}, &block)
    make_request(:get, endpoint, params, &block)
  end
end
