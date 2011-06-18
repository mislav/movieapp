require 'faraday_stack'
require 'nibbler/json'
require 'addressable/template'

module NibbleSpec
  protected
  attr_accessor :faraday

  def build_stack(*args, &block)
    self.faraday = FaradayStack.build(*args, &block)
  end
  
  def get(method, url)
    template = Addressable::Template.new url.to_s
    parser = block_given? && Class.new(Nibbler, &Proc.new)
    
    (class << self; self; end).send(:define_method, method) do |params|
      response = faraday.get(template.expand(params || {}))
      if parser
        data = response.body
        type = response.headers['content-type'].to_s.split(';').first
        data = Nibbler::JsonDocument.new(data) if type =~ /\/json$/
        parser.parse(data)
      else
        response.body
      end
    end
  end
end
