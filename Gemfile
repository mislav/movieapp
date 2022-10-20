source 'https://rubygems.org'

# ruby '2.5.1'

gem 'railties', '~> 4.2.11'
gem 'activemodel', '~> 4.2.11'
gem 'tzinfo'
gem 'unicorn'
gem 'test-unit', '~> 3.0'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

group :production do
  gem 'dalli'
  gem 'rack-cache'
  gem 'kgio'
  gem 'rails_12factor'
end

gem 'mingo', '~> 0.6.0' #, :path => '/Users/mislav/p/mingo'
gem 'mongo-rails-instrumentation'
gem 'bson_ext', '>= 1.12.5', :require => nil
gem 'will_paginate', '~> 3.0' #, :path => '/Users/mislav/.coral/will_paginate-mislav'
gem 'escape_utils'
gem 'choices' #, :path => '/Users/mislav/Projects/choices'
gem 'never-forget' #, :path => '/Users/mislav/p/never-forget'

gem 'omniauth-twitter'

gem 'fickle-ruby', '~> 1.0'

group :extras do
  gem 'nibbler', '~> 1.3' #, :path => '/Users/mislav/Projects/nibbler'
  gem 'addressable', '~> 2.8'
  gem 'faraday', '~> 0.8.9'
  gem 'faraday_middleware', '~> 0.8.4'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.8'
  gem 'rspec-its'
  gem 'byebug'
end

group :test do
  gem 'webmock', '~> 1.8.0'
  gem 'vcr', '~> 2.0'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end
