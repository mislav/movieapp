# clear Mingo collections before each scenario
Before do
  Mingo.db.collections.each(&:remove)
end
