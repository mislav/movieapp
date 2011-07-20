BSON::ObjectId.class_eval do
  def self.from_object(obj)
    obj.respond_to?(:to_str) ? from_string(obj) : obj.id
  end
end
