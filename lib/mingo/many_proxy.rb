class Mingo
  module Many
    def many(property, *args, &block)
      proxy_class = block_given?? Class.new(ManyProxy, &block) : ManyProxy
      ivar = "@#{property}"

      define_method(property) {
        (instance_variable_defined?(ivar) && instance_variable_get(ivar)) ||
        instance_variable_set(ivar, proxy_class.new(self, property, *args))
      }
    end
  end

  class ManyProxy
    def self.decorate_with(mod = nil, &block)
      if mod or block_given?
        @decorate_with = mod || Module.new(&block)
      else
        @decorate_with
      end
    end
    
    def self.decorate_each(&block)
      if block_given?
        @decorate_each = block
      else
        @decorate_each
      end
    end
    
    def initialize(parent, property, mapping)
      @parent = parent
      @property = property
      # TODO: ugh, improve naming
      @model, @self_referencing_key, @forward_referencing_key = analyze_mapping mapping
      @counter_cache_field = "#{@property}_count"
      @join_loaded = nil
      @loaded = nil
    end
  
    undef :inspect
    undef :to_a if instance_methods.include? 'to_a'
  
    def object_ids
      join_docs = load_join
      join_docs = join_docs.select(&Proc.new) if block_given?
      join_docs.map { |doc| doc[@forward_referencing_key] }
    end
    
    def size
      (counter_cache? && counter_cache) || (@join_loaded && @join_loaded.size) || join_cursor.count
    end
    
    def include?(doc)
      !!find_join_doc(doc.id)
    end
  
    def convert(doc)
      {@self_referencing_key => @parent.id, @forward_referencing_key => doc.id}
    end
  
    def <<(doc)
      doc = convert(doc)
      doc['_id'] = join_collection.save doc
      change_counter_cache(1)
      load_join << doc if @join_loaded
      unload_collection
      self
    end
  
    def delete(doc)
      doc = convert(doc)
      if join_doc = find_join_doc(doc[@forward_referencing_key])
        join_collection.remove :_id => join_doc['_id']
        change_counter_cache(-1)
        unload_collection
        @join_loaded.delete join_doc
      end
      doc
    end
    
    def loaded?
      !!@loaded
    end

    def reload
      @loaded = @join_loaded = nil
      self
    end
    
    def find(selector = {}, options = {}, &block)
      @model.find(selector, find_options.merge(options), &block)
    end
    
    def respond_to?(method, priv = false)
      super || method_missing(:respond_to?, method, priv)
    end

    def reset_counter_cache
      delta = join_cursor.count - counter_cache
      change_counter_cache delta
      counter_cache
    end

    def cache_key
      [@parent, @property, counter_cache]
    end

    private
  
    def method_missing(method, *args, &block)
      load_collection
      @loaded.send(method, *args, &block)
    end
    
    def join_collection
      @join_collection ||= @parent.class.collection[@property.to_s]
    end
    
    def counter_cache
      @counter_cache ||= @parent[@counter_cache_field].to_i
    end
    
    def counter_cache?
      !!@parent[@counter_cache_field]
    end
    
    def change_counter_cache(by)
      @counter_cache = counter_cache + by
      @parent.update '$inc' => { @counter_cache_field => by }
    end
    
    # Example: {self => 'user_id', 'movie_id' => Movie}
    def analyze_mapping(mapping)
      model = self_referencing_key = forward_referencing_key = nil
      mapping.each do |key, value|
        if key == @parent.class then self_referencing_key = value.to_s
        elsif value < Mingo
          forward_referencing_key = key.to_s
          model = value
        end
      end
      [model, self_referencing_key, forward_referencing_key]
    end
    
    def find_options
      @find_options ||= begin
        decorator = self.class.decorate_with
        decorate_block = self.class.decorate_each
        
        if decorator or decorate_block
          {:transformer => lambda { |doc|
            @model.new(doc).tap do |obj|
              obj.extend decorator if decorator
              if decorate_block
                join_doc = find_join_doc(doc['_id'])
                decorate_block.call(obj, join_doc)
              end
            end
          }}
        else
          {}
        end
      end
    end
    
    def load_join
      @join_loaded ||= join_cursor.to_a
    end
    
    def find_join_doc(forward_id)
      load_join.find { |d| d[@forward_referencing_key] == forward_id }
    end
    
    def join_cursor
      # TODO: make options configurable
      join_collection.find({@self_referencing_key => @parent.id}, :sort => '_id')
    end
  
    def load_collection
      @loaded ||= if self.object_ids.empty? then []
      else find(self.object_ids)
      end
    end
  
    def unload_collection
      @loaded = nil
    end
  end
end