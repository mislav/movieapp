class Mingo
  module Changes
    def self.included(base)
      base.after_save :clear_changes
    end
    
    attr_reader :changes
    
    def initialize(*args)
      @changes = {}
      super
    end

    def []=(key, value)
      record_change(key, value)
      super
    end
    
    def changed?
      changes.any?
    end
    
    private

    def record_change(key, value)
      old_value = self[key]
      unless value == old_value
        memo = (changes[key.to_sym] ||= [old_value])
        memo[0] == value ? changes.delete(key.to_sym) : (memo[1] = value)
      end
    end

    def clear_changes
      changes.clear
    end
    
    def values_for_update
      changes.inject({}) do |doc, (key, values)|
        value = values[1]
        if value
          doc['$set'] ||= {}
          doc['$set'][key] = value
        else
          doc['$unset'] ||= {}
          doc['$unset'][key] = 1
        end
        doc
      end
    end
  end
end
