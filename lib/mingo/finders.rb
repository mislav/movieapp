class Mingo
  module Finders
    def first(id_or_selector = nil, options = {})
      unless id_or_selector.nil? or Hash === id_or_selector
        id_or_selector = BSON::ObjectId[id_or_selector]
      end
      options = { :transformer => lambda {|doc| self.new(doc)} }.update(options)
      collection.find_one(id_or_selector, options)
    end
    
    def find(selector = {}, options = {}, &block)
      selector = {:_id => {'$in' => selector}} if Array === selector
      options = { :transformer => lambda {|doc| self.new(doc)} }.update(options)
      collection.find(selector, options, &block)
    end
  end
end
