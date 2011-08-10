require 'mongo_pagination'
require 'will_paginate/array'
require 'will_paginate/per_page'

WillPaginate.per_page = 10

unless [].respond_to? :page
  Array.class_eval do
    def page(num)
      paginate(:page => num)
    end
  end
end
