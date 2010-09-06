require 'will_paginate/finders/base'

Mingo.class_eval do
  extend WillPaginate::Finders::Base
  
  def self.wp_query(options, pager, args)
    options.update(:skip => pager.offset, :limit => pager.per_page) 

    cursor = find(nil, options)
    pager.replace cursor.to_a

    unless pager.total_entries
      pager.total_entries = cursor.count
    end
  end
end
