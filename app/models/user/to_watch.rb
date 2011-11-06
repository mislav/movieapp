module User::ToWatch
  def to_watch(options = nil)
    # memoize the default association, not ones created with custom options
    return @to_watch if options.nil? and defined?(@to_watch)
    association = User::MoviesAssociation.new(self, :to_watch, options || {})
    @to_watch = association if options.nil?
    association
  end
end
