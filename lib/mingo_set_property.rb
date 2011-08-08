require 'set'

class Mingo
  module SetProperty
    def property(name, options = nil)
      if options and :set == options[:type]
        methods = Module.new
        methods.module_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}
            @#{name} ||= Mingo::Set.new self, '#{name}', self['#{name}']
          end

          def #{name}=(values)
            #{name}.replace(values)
          end

          def #{name}?
            if defined?(@#{name}) then !@#{name}.empty?
            else
              !self['#{name}'].nil? and !self['#{name}'].empty?
            end
          end
        RUBY
        include methods
      else
        super(name)
      end
    end
  end

  # A Set object that has a reference to its parent Mingo document and
  # automatically updates the corresponding field with atomic operations when
  # elements are added or removed from the set.
  class Set < ::Set
    def initialize(parent, name, values)
      @auto_update = true
      without_auto_updating { super(values) }
      @parent = parent
      @name = name.to_s
    end

    def add(value)
      if include?(value) then self
      else
        if auto_update?
          if parent_persisted?
            update_parent '$addToSet' => {@name => value}
          else
            parent_property << value
          end
        end
        super
      end
    end
    alias << add

    def delete(value)
      if include? value
        if auto_update?
          if parent_persisted?
            update_parent '$pull' => {@name => value} 
          else
            parent_property.delete value
          end
        end
        super
      else self
      end
    end

    # clear + merge
    def replace(values)
      if auto_update?
        if parent_persisted?
          update_parent '$set' => {@name => values.to_a}
        else
          parent_property_set(values.to_a)
        end
      end
      without_auto_updating { super }
    end

    def clear
      if auto_update?
        if parent_persisted?
          update_parent '$unset' => {@name => true}
        else
          parent_property_set(nil)
        end
      end
      super
    end

    private

    def auto_update?
      @auto_update
    end

    def without_auto_updating
      old_setting = @auto_update
      @auto_update = false
      begin
        yield
      ensure
        @auto_update = old_setting
      end
    end

    def parent_persisted?
      @parent.persisted?
    end

    def parent_property?
      !!@parent[@name]
    end

    def parent_property
      @parent[@name] ||= []
    end

    def parent_property_set(obj)
      @parent[@name] = obj
    end

    def update_parent(doc)
      @parent.update(doc)
    end
  end
end
