class Mingo
  # Custom Cursor subclass.
  # TODO: contribute this to the official driver
  class Cursor < Mongo::Cursor
    module CollectionPlugin
      def find(*args)
        cursor = Cursor.from_mongo(super(*args))
        
        if block_given?
          yield cursor
          cursor.close()
          nil
        else
          cursor
        end
      end
    end
    
    def self.from_mongo(cursor)
      new(cursor.collection).tap do |sub|
        cursor.instance_variables.each { |ivar|
          sub.instance_variable_set(ivar, cursor.instance_variable_get(ivar))
        }
      end
    end
    
    def empty?
      !has_next?
    end
    
    def by_ids?
      Hash === selector[:_id] && selector[:_id]["$in"]
    end
    
    def reverse
      check_modifiable
      if by_ids? and !order
        selector[:_id]["$in"] = selector[:_id]["$in"].reverse
        self
      elsif order && (!(Array === order) || !(Array === order.first) || order.size == 1)
        if Array === order
          field, dir = *order.flatten
          dir = Mongo::Conversions::ASCENDING_CONVERSION.include?(dir.to_s) ? -1 : 1
        else
          field = order
          dir = -1
        end
        sort(field, dir)
      else
        raise "can't reverse complex query"
      end
    end
    
    private

    alias refresh_without_sorting refresh

    def refresh
      if !@query_run && by_ids? && !order
        limit_ids do
          preload_cache
          sort_cache_by_ids
        end
      else
        refresh_without_sorting
      end
    end
    
    def limit_ids
      if @limit > 0 || @skip > 0
        ids = selector[:_id]["$in"]
        old_skip = @skip
        selector[:_id]["$in"] = Array(ids[@skip, @limit > 0 ? @limit : ids.size])
        @skip = 0
        begin
          yield
        ensure
          @skip = old_skip
          selector[:_id]["$in"] = ids
        end
      else
        yield
      end
    end
    
    def preload_cache
      begin
        refresh_without_sorting
      end until @cursor_id.zero? || closed? || @n_received.to_i < 1
    end
    
    def sort_cache_by_ids
      ids = selector[:_id]["$in"]
      results = []
      
      index = @cache.inject({}) do |all, doc|
        if doc["$err"]
          results << doc
        else
          all[doc["_id"]] = doc
        end
        all
      end
      
      ids.each do |id|
        if doc = index[id]
          results << doc
        end
      end
      
      @cache = results
    end
  end
end
