require 'will_paginate/page_number'
require 'will_paginate/per_page'
require 'mongo'

module MongoPagination
  def page(num)
    pagenum = WillPaginate::PageNumber(num.nil? ? 1 : num)
    per_page = limit > 0 ? limit : WillPaginate.per_page

    self.limit per_page unless self.limit > 0
    self.skip pagenum.to_offset(per_page)
    self.extend CursorExtension
    self.current_page = pagenum
    self
  end

  def paginate(options)
    pagenum = options.fetch(:page) { raise ":page parameter missing" }
    per_page = options[:per_page]

    self.limit per_page.to_i if per_page
    self.page(pagenum)
  end

  module CursorExtension
    attr_accessor :current_page

    def per_page
      limit > 0 ? limit : nil
    end

    def offset
      skip
    end

    def total_entries
      @total_entries ||= count
    end

    def total_pages
      (total_entries / per_page) + 1
    end
  end

  ::Mongo::Cursor.send :include, self
end
