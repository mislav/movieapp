require 'active_support/ordered_hash'

module Enumerable
  def ordered_index_by
    each_with_object(ActiveSupport::OrderedHash.new) do |elem, accum|
      accum[yield(elem)] = elem
    end
  end
end
