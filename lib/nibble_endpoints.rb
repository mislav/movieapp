require 'faraday_middleware'
require 'nibbler/json'
require 'addressable/uri'
require 'addressable/template'

module NibbleEndpoints
  def get(endpoint, params = {}, &block)
    process_request(:get, endpoint, params, &block)
  end

  def get_raw(endpoint, params = {}, &block)
    make_request(:get, endpoint, params, &block)
  end
  
  def path_for(endpoint, params = {})
    template, = endpoints.fetch(endpoint.to_sym) {
      raise ArgumentError, "unknown endpoint #{endpoint.inspect}"
    }
    template.expand(default_params.merge(params))
  end
  
  def url_for(endpoint, params = {})
    path = path_for(endpoint, params)
    # TODO: figure out why + vs %20
    connection.build_url(path).to_s.gsub('+', '%20')
  end

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

  def default_params(params = nil)
    if params or block_given?
      @default_params = params || Proc.new
    else
      @default_params = {} unless defined? @default_params
      @default_params = @default_params.call if @default_params.is_a? Proc
      @default_params
    end
  end

  def make_request(method, endpoint, params = {})
    url = path_for(endpoint, params)
    connection.run_request(method, url, nil, nil) do |request|
      yield request if block_given?
    end
  end

  def process_request(method, endpoint, params = {}, &block)
    _, parser = endpoints.fetch(endpoint.to_sym) {
      raise ArgumentError, "unknown endpoint #{endpoint.inspect}"
    }
    response = make_request(method, endpoint, params, &block)

    if parser
      process_response(response, parser)
    else
      response
    end
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
