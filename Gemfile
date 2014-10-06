source 'https://rubygems.org'

ruby '2.1.3'

gem 'railties', '~> 3.2.11'
gem 'tzinfo'
gem 'unicorn'

group :assets do
  gem 'sass-rails', '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '~> 1.2.2'
  gem 'compass', '~> 0.12.0'
  gem 'compass-rails'
  gem 'bootstrap-sass', '~> 2.2.1'
end

group :production do
  gem 'dalli'
  gem 'rack-cache'
  gem 'kgio'
end

gem 'mingo', '>= 0.3.0' #, :path => '/Users/mislav/Projects/mingo'
gem 'mongo_ext', '>= 0.19.3', :require => nil
gem 'mongo-rails-instrumentation'
gem 'bson_ext', '>= 1.1.1', :require => nil
gem 'will_paginate', '~> 3.0' #, :path => '/Users/mislav/.coral/will_paginate-mislav'
gem 'escape_utils'
gem 'choices' #, :path => '/Users/mislav/Projects/choices'
gem 'never-forget' #, :path => '/Users/mislav/Projects/never-forget'
gem 'twin' #, :path => '/Users/mislav/Projects/twin'

gem 'omniauth-twitter'
gem 'omniauth-facebook'

gem 'fickle-ruby', '~> 1.0'

group :extras do
  gem 'nokogiri', '~> 1.4.1'
  gem 'nibbler', '~> 1.3' #, :path => '/Users/mislav/Projects/nibbler'
  gem 'addressable', '~> 2.1'
  gem 'faraday', '~> 0.8.9'
  gem 'faraday_middleware', '~> 0.8.4'
  gem 'simple_oauth'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.8.0'
  gem 'byebug'
end

group :test do
  gem 'webmock', '~> 1.8.0'
  gem 'vcr'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end
