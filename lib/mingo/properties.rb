require 'active_support/concern'

class Mingo
  module Properties
    extend ActiveSupport::Concern

    included do
      instance_variable_set('@properties', Array.new)
    end

    module ClassMethods
      attr_reader :properties

      def property(name, options = nil)
        self.properties << name.to_sym

        setter_name = "#{name}="
        unless method_defined?(setter_name)
          methods = Module.new
          methods.module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}(&block)
              self.[](#{name.to_s.inspect}, &block)
            end

            def #{setter_name}(value)
              self.[]=(#{name.to_s.inspect}, value)
            end
          RUBY
          include methods
        end

        if defined? @subclasses
          @subclasses.each { |klass| klass.property(property_name, options) }
        end
      end

      def inherited(klass)
        super
        (@subclasses ||= Array.new) << klass
        klass.instance_variable_set('@properties', self.properties.dup)
      end
    end

    def initialize(*)
      super
      @_data = {}
    end

    def inspect
      str = "<##{self.class.to_s}"
      str << self.class.properties.map { |p| " #{p}=#{self.send(p).inspect}" }.join('')
      str << '>'
    end

    def [](field, &block)
      @_data.send(:[], field, &block)
    end

    def []=(field, value)
      @_data[field] = value
    end

    def to_hash
      @_data.dup
    end

    def merge!(other)
      @_data.merge!(other.to_hash)
      self
    end

    def replace(other)
      @_data.replace(other.to_hash)
      self
    end
  end
end
