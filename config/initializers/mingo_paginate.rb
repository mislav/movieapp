require 'will_paginate/finders/base'

Mingo.class_eval do
  def self.paginate(options)
    find.paginate(options)
  end
end

Mingo::Cursor.class_eval do
  include WillPaginate::Finders::Base
  
  def wp_query(options, pager, args)
    self.limit pager.per_page
    self.skip pager.offset
    self.sort options[:sort]
    pager.replace self.to_a
    pager.total_entries = self.count unless pager.total_entries
  end
end
