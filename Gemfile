source :rubygems

gem 'railties', '~> 3.1.0'
gem 'tzinfo'

group :assets do
  gem 'sass-rails', '~> 3.1.0'
  gem 'coffee-rails', '~> 3.1.0'
  gem 'uglifier'
  gem 'compass', '~> 0.12.alpha'
end

group :production do
  gem 'therubyracer-heroku', '~> 0.8.1.pre3', :require => nil
  gem 'dalli'
end

gem 'mingo', '>= 0.3.0' #, :path => '/Users/mislav/Projects/mingo'
gem 'mongo_ext', '>= 0.19.3', :require => nil
gem 'mongo-rails-instrumentation'
gem 'bson_ext', '>= 1.1.1', :require => nil
gem 'twitter-login', '~> 0.4.0', :require => 'twitter/login' #, :path => '/Users/mislav/Projects/twitter-login'
gem 'will_paginate', '~> 3.0' #, :path => '/Users/mislav/.coral/will_paginate-mislav'
gem 'facebook-login', '~> 0.2.0', :require => 'facebook/login' #, :path => '/Users/mislav/Projects/facebook'
gem 'escape_utils'
gem 'choices' #, :path => '/Users/mislav/Projects/choices'

group :extras do
  gem 'nokogiri', '~> 1.4.1'
  gem 'nibbler', '~> 1.1' #, :path => '/Users/mislav/Projects/scraper'
  gem 'yajl-ruby', '~> 0.7'
  gem 'addressable', '~> 2.1'
  gem 'faraday-stack' #, :path => '/Users/mislav/Projects/faraday-stack'
  gem 'faraday_middleware'
  gem 'simple_oauth'
end

group :development do
  gem 'mongrel', :require => nil, :platforms => :ruby_18
  gem 'thin', :require => nil, :platforms => :ruby_19
end

group :development, :test do
  gem 'rspec-rails', '~> 2.6.1'
  gem 'ruby-debug', :platforms => :mri_18
  gem 'ruby-debug19', :platforms => :mri_19
end

group :test do
  gem 'webmock'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end
