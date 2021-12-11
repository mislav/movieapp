require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bigdecimal'
class BigDecimal
    class << self
        def new(val)
            BigDecimal(val)
        end
    end
end

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
