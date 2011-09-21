require 'movie_title'

module Movie::Permalink
  extend ActiveSupport::Concern

  included do
    property :permalink
    collection.ensure_index :permalink
    before_save :generate_permalink, :if => :no_permalink?
    
    def permalink=(value)
      super(value.present? ? generate_unique_permalink(value) : nil)
    end
  end

  module ClassMethods
    def find_by_permalink(string, options = {})
      if string =~ /^[0-9a-f]{24}$/ then first(string, options)
      else first({permalink: string}, options)
      end
    end
  end

  def no_permalink?
    permalink.blank?
  end

  def to_param
    no_permalink? ? self.id.to_s : permalink
  end

  def generate_permalink
    self.permalink = MovieTitle::parameterize(title, year) if eligible_for_permalink?
  end

  private

  def eligible_for_permalink?
    title.present? and year.present? and (locked_value?(:year) || netflix_id)
  end

  def permalink_taken?(name)
    !!self.class.first({ permalink: name, _id: {'$ne' => self.id} }, fields: :_id)
  end

  def generate_unique_permalink(name)
    name.dup.tap do |unique_name|
      unique_name.sub!(/(?:_(\d+))?$/) { "_#{$1 ? $1.to_i + 1 : 2}" } while permalink_taken?(unique_name)
    end
  end
end
