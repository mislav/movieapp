require "mingo"

BSON::ObjectId.class_eval do
  def self.from_object(obj)
    obj.respond_to?(:to_str) ? from_string(obj) : obj.id
  end
end

# TODO: fix cache_key in Mingo
Mingo::ManyProxy.class_eval do
  def cache_key
    parent_key = @parent.respond_to?(:cache_key) ? @parent.cache_key : @parent
    [parent_key, @property, counter_cache].to_param
  end
end

Mongo::Cursor.class_eval do
  def first_selector_id
    Hash === selector[:_id] ? selector[:_id]['$in'].try(:first) : nil
  end
end