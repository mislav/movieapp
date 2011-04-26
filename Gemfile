source :rubygems

gem 'rails', '~> 3.0.0.rc' #, :path => '/Users/mislav/.coral/rails-3-0-stable'

gem 'hashie', '~> 0.4.0'
gem 'mingo', '>= 0.2.0' #, :path => '/Users/mislav/Projects/mingo'
gem 'mongo_ext', '>= 0.19.3', :require => nil
gem 'bson_ext', '>= 1.1.1', :require => nil
gem 'twitter-login', '~> 0.4.0', :require => 'twitter/login' #, :path => '/Users/mislav/Projects/twitter-login'
gem 'will_paginate', '3.0.pre2' #, :path => '/Users/mislav/.coral/will_paginate-mislav'
gem 'facebook-login', '~> 0.2.0', :require => 'facebook/login' #, :path => '/Users/mislav/Projects/facebook'
gem 'haml', '~> 3.1'
gem 'compass'
gem 'escape_utils'
gem 'choices' #, :path => '/Users/mislav/Projects/choices'

group :extras do
  gem 'nokogiri', '~> 1.4.1'
  gem 'oauth', '~> 0.4.0'
  gem 'nibbler', '~> 1.1' #, :path => '/Users/mislav/Projects/scraper'
  gem 'yajl-ruby', '~> 0.7.7'
  gem 'addressable', '~> 2.1.2'
end

group :development do
  gem 'mongrel', :require => nil, :platforms => :ruby_18
  gem 'thin', :require => nil, :platforms => :ruby_19
end

group :development, :test do
  gem 'rspec-rails', '~> 2.3.0'
  gem 'ruby-debug', :platforms => :ruby_18
  gem 'ruby-debug19', :platforms => :ruby_19
end

group :test do
  gem 'webmock'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end