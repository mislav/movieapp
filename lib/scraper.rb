## A minimalistic, declarative HTML scraper

class Scraper
  attr_reader :doc
  
  # Accepts string, open file, or Nokogiri-like document
  def initialize(doc)
    @doc = self.class.convert_document(doc)
    initialize_plural_accessors
  end
  
  # Initialize a new scraper and process data
  def self.parse(html)
    new(html).parse
  end
  
  # Specify a new singular scraping rule
  def self.element(*args, &block)
    selector, name, delegate = parse_rule_declaration(*args, &block)
    rules[name] = [selector, delegate]
    attr_accessor name
    name
  end
  
  # Specify a new plural scraping rule
  def self.elements(*args, &block)
    name = element(*args, &block)
    rules[name] << true
  end
  
  # Let it do its thing!
  def parse
    self.class.rules.each do |target, (selector, delegate, plural)|
      if plural
        @doc.search(selector).each do |node|
          send(target) << parse_result(node, delegate)
        end
      else
        send("#{target}=", parse_result(@doc.at(selector), delegate))
      end
    end
    self
  end
  
  protected
  
  # `delegate` is optional, but should respond to `call` or `parse`
  def parse_result(node, delegate)
    if delegate
      delegate.respond_to?(:call) ? delegate.call(node) : delegate.parse(node)
    elsif node.respond_to? :inner_text
      node.inner_text
    else
      node.to_s
    end unless node.nil?
  end
  
  private
  
  def self.rules
    @rules ||= {}
  end
  
  def self.inherited(subclass)
    subclass.rules.update self.rules
  end
  
  # Rule declaration is in Hash or single argument form:
  # 
  #   { '//some/selector' => :name, :with => delegate }
  #     #=> ['//some/selector', :name, delegate]
  #   
  #   :title
  #     #=> ['title', :title, nil]
  def self.parse_rule_declaration(*args, &block)
    options, name = Hash === args.last ? args.pop : {}, args.first
    delegate = options.delete(:with)
    selector, property = name ? [name.to_s, name.to_sym] : options.to_a.flatten
    raise ArgumentError, "invalid rule declaration: #{args.inspect}" unless property
    # eval block in context of a new scraper subclass
    delegate = Class.new(delegate || Scraper, &block) if block_given?
    return selector, property, delegate
  end
  
  def initialize_plural_accessors
    self.class.rules.each do |name, (s, k, plural)|
      send("#{name}=", []) if plural
    end
  end
  
  def self.convert_document(doc)
    if String === doc or IO === doc or %w[Tempfile StringIO].include? doc.class.name
      require 'nokogiri' unless defined? ::Nokogiri
      Nokogiri doc
    else
      doc
    end
  end
end
