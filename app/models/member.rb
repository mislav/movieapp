class Member < ActiveRecord::Base
  has_many :roles
  has_many :movies, :through => :roles
end
