source 'https://rubygems.org'

gem 'railties', '~> 6.1.0'
gem 'activemodel', '~> 6.1.0'
gem 'tzinfo'
gem 'puma'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

group :production do
  gem 'dalli'
  gem 'rack-cache'
end

gem 'mongo', '< 2.0.0'
gem 'bson_ext', '>= 1.12.5', :require => nil
gem 'will_paginate', '~> 3.3.1'
gem 'choices' #, :path => '/Users/mislav/Projects/choices'

gem 'omniauth-twitter'

group :extras do
  gem 'nibbler', '~> 1.3' #, :path => '/Users/mislav/Projects/nibbler'
  gem 'addressable', '~> 2.8'
  gem 'faraday', '< 2.0'
  gem 'faraday_middleware', '~> 1.2.0'
end

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'rspec-its'
  gem 'byebug'
end

group :test do
  gem 'webmock', '~> 3.18'
  gem 'vcr', '~> 2.0'
  gem 'cucumber-rails', :require => nil
  gem 'capybara', :require => nil
  gem 'launchy', :require => nil
end
