class Movie < ActiveRecord::Base
  validates_numericality_of :year, :greater_than => 1890,
    :message => "ṁotion pictures didn't exist at that time"
  
  has_many :roles
  has_many :members, :through => :roles
  has_many :actors, :through => :roles, :source => :member,
    :conditions => ['roles.position = ?', 'actor']
  
  has_one :director, :through => :roles, :source => :member,
    :conditions => ['roles.position = ?', 'director']
end
