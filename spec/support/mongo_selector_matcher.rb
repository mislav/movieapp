module MongoSelectorMatcher
  class Selector
    def initialize(selector)
      @selector = selector
    end
    
    def matches?(doc)
      @doc = doc
      selector_with_id = @selector.merge(:_id => @doc.id)
      @doc.class.collection.find(selector_with_id, :fields => []).has_next?
    end
    
    def failure_message_for_should
      "expected #{@doc.inspect} to match mongo selector #{@selector.inspect}"
    end
    
    def failure_message_for_should_not
      "didn't expect #{@doc.inspect} to match mongo selector #{@selector.inspect}"
    end
    
    # does_not_match?(actual)
    # description #optional
  end
  
  def match_selector(selector)
    Selector.new(selector)
  end
end

RSpec.configure do |config|
  config.include MongoSelectorMatcher
end
