require 'addressable/uri'

# feature-detect the bug
unless Addressable::URI.parse('/?a=1&b=2') === '/?b=2&a=1'
  # fix `normalized_query` by sorting query key-value pairs
  # (rejected: https://github.com/sporkmonger/addressable/issues/28)
  class Addressable::URI
    class << self
      alias normalize_component_without_query_fix normalize_component
    
      def normalize_component(component, character_class = CharacterClasses::RESERVED + CharacterClasses::UNRESERVED)
        normalized = normalize_component_without_query_fix(component, character_class)
        if character_class == Addressable::URI::CharacterClasses::QUERY
          pairs = normalized.split('&').sort_by { |pair| pair[0, pair.index('=') || pair.length] }
          normalized = pairs.join('&')
        end
        normalized
      end
    end
  end
end
