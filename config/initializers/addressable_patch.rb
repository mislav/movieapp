require 'addressable/uri'

# fix `normalized_query` by sorting query key-value pairs
class Addressable::URI
  class << self
    alias old_normalize_component normalize_component
    
    def normalize_component(component, character_class = CharacterClasses::RESERVED + CharacterClasses::UNRESERVED)
      normalized = old_normalize_component(component, character_class)
      if character_class == Addressable::URI::CharacterClasses::QUERY
        pairs = normalized.split('&').sort_by { |pair| pair[0, pair.index('=') || pair.length] }
        normalized = pairs.join('&')
      end
      normalized
    end
  end
end
