task :default => :cucumber

task :cucumber do
  cmd = 'bundle exec cucumber -f progress -t ~@wip'
  raise("#{cmd} failed") unless ruby("-S #{cmd}")
end