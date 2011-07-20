require 'set'

class Mingo
  module SetProperty
    def property(name, options = nil)
      if options and :set == options[:type]
        class_eval <<-RUBY, __FILE__, __LINE__
          def #{name}
            @#{name} ||= Mingo::Set.new self, '#{name}', self['#{name}']
          end

          def #{name}?
            if defined?(@#{name}) then !@#{name}.empty?
            else
              !self['#{name}'].nil? and !self['#{name}'].empty?
            end
          end
        RUBY
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
      super(values)
      @parent = parent
      @name = name.to_s
    end

    def add(value)
      if include? value then self
      else
        update_parent '$addToSet' => {@name => value}
        super
      end
    end
    alias << add

    def delete(value)
      if include? value
        update_parent '$pull' => {@name => value} 
        super
      else self
      end
    end

    private

    def update_parent(doc)
      @parent.update(doc)
    end
  end
end
