require 'active_support/memoizable'

# mixin for comparing movie objects that have `name` and `year`
module MovieTitle
  RomanNumeralsMap = Hash[%w[i ii iii iv v vi vii viii ix xi xii].each_with_index.map { |s,i| [s, i+1] }]
  RomanNumerals = /\b(?:i?[vx]|[vx]?i{1,3})\b/i
  
  extend ActiveSupport::Memoizable
  
  def self.normalize_title(original)
    ActiveSupport::Inflector.transliterate(original).tap do |title|
      title.downcase!
      title.gsub!('&', ' and ')
      title.gsub!(/[^\w\s]/, '')
      title.squish!
      title.sub!(/^(the|a) /, '')
      title.gsub!(' the ', ' ')
      title.gsub!(RomanNumerals) { RomanNumeralsMap[$&] }
      title.gsub!(/\b(episode|season|part) one\b/, '\1 1')
    end
  end
  
  def self.parameterize(original, year)
    ActiveSupport::Inflector.transliterate(original).tap do |title|
      title.gsub!(/((?:^|-|:)\s*)the\b/i, '\1')
      title.gsub!('&', ' and ')
      title.gsub!(/[^\w\s':]/, '')
      title.squish!
      title.gsub!(RomanNumerals) { RomanNumeralsMap[$&.downcase] }
      title.gsub!(/\b(episode|season|part) one\b/i, '\1 1')
      title << " (#{year})" if year
    end.tr(' ', '_')
  end
  
  def normalized_title
    ::MovieTitle::normalize_title(self.name)
  end
  memoize :normalized_title
  
  def ==(other)
    other.respond_to? :normalized_title and other.respond_to? :year and
      self.normalized_title == other.normalized_title and self.year == other.year
  end
end
