source 'https://rubygems.org'

gem 'railties', '~> 3.2.11'
gem 'tzinfo'

group :assets do
  gem 'sass-rails', '~> 3.2'
  gem 'coffee-rails', '~> 3.2'
  gem 'uglifier'
  gem 'compass', '~> 0.12.alpha'
  gem 'bootstrap-sass', '~> 2.2.1'
end

group :production do
  gem 'therubyracer-heroku', '~> 0.8.1.pre3', :require => nil
  gem 'dalli'
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
gem 'rails-behaviors'

gem 'omniauth-twitter'
gem 'omniauth-facebook'

group :extras do
  gem 'nokogiri', '~> 1.4.1'
  gem 'nibbler', '~> 1.3' #, :path => '/Users/mislav/Projects/nibbler'
  gem 'addressable', '~> 2.1'
  gem 'faraday', '~> 0.8.0.rc'
  gem 'faraday_middleware'
  gem 'simple_oauth'
end

group :development do
  gem 'mongrel', :require => nil, :platforms => :ruby_18
  gem 'thin', :require => nil, :platforms => :ruby_19
end

group :development, :test do
  gem 'rspec-rails', '~> 2.8.0'
  gem 'ruby-debug', :platforms => :mri_18
  gem 'ruby-debug19', :platforms => :mri_19
end

group :test do
  gem 'webmock', '~> 1.8.0'
  gem 'vcr'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end
