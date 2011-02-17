require 'failsafe_store'
require 'net/http'

module ApiCache
  class << self
    extend ActiveSupport::Memoizable
    
    attr_writer :perform_caching
    
    def perform_caching?
      @perform_caching
    end
    
    def cache
      FailsafeStore.new Rails.root + 'tmp/cache', :expires_in => 1.day,
        :exceptions => [Net::HTTPServerException, 'Tmdb::APIError']
    end
    memoize :cache
    
    def fetch(namespace, key)
      if perform_caching?
        cache.fetch(key, :namespace => namespace) { yield }
      else
        yield
      end
    end
  end
  
  self.perform_caching = Rails.application.config.api_caching
end
