# Movie metadata:
#
# - title (English and original)
# - year
# - plot
# - cover image
# - director
# - genre(s)
# - running time
# - main cast
# - link to trailer
# 
class Movie < ActiveRecord::Base
  validates_presence_of :title
  validates_numericality_of :year, :greater_than => 1890,
    :message => "has to be a number greater than 1890"
    
  has_many :roles
  has_many :members, :through => :roles
  has_many :actors, :through => :roles, :source => :member,
    :conditions => ['roles.position = ?', 'actor']
  
  has_one :director, :through => :roles, :source => :member,
    :conditions => ['roles.position = ?', 'director']
end
