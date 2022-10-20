class Mingo
  module Timestamps
    def self.included(base)
      base.before_update :touch_updated_timestamp
    end

    def created_at
      @created_at ||= self.id && self.id.generation_time
    end

    def updated_at
      self['updated_at'] || created_at
    end

    protected

    def touch_updated_timestamp
      self['updated_at'] = Time.now if changed?
    end
  end
end
