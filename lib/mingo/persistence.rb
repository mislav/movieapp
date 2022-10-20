require 'active_support/concern'

class Mingo
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      def create(obj = nil)
        new(obj).tap do |object|
          yield object if block_given?
          object.save
        end
      end
    end

    def initialize(*args)
      @destroyed = false
      super
    end

    def persisted?
      !!id
    end

    def save(options = {})
      if persisted?
        hash = values_for_update
        unless hash.empty?
          update(hash, options)
        end
      else
        self['_id'] = self.class.collection.insert(self.to_hash, options)
      end
    end

    def update(doc, options = {})
      self.class.collection.update({'_id' => self.id}, doc, options)
    end

    def reload
      doc = self.class.first(id, :transformer => nil)
      replace doc
      self
    end

    def destroy
      self.class.collection.remove('_id' => self.id)
      @destroyed = true
      self.freeze
    end

    def destroyed?
      @destroyed
    end

    private

    def values_for_update
      self.to_hash
    end
  end
end
