module Cache
  class << self
    attr_writer :perform_caching
  end
  self.perform_caching = false

  def self.perform_caching?
    @perform_caching
  end

  def self.store
    Rails.cache
  end

  def self.fetch(key, options = {})
    if perform_caching?
      store.fetch(key, options) { yield }
    else
      yield
    end
  end
end
