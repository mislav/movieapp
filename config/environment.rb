# Load the rails application
require File.expand_path('../application', __FILE__)

ENV['MEMCACHE_SERVERS']  ||= ENV['MEMCACHIER_SERVERS']
ENV['MEMCACHE_USERNAME'] ||= ENV['MEMCACHIER_USERNAME']
ENV['MEMCACHE_PASSWORD'] ||= ENV['MEMCACHIER_PASSWORD']

# Initialize the rails application
Movies::Application.initialize!
