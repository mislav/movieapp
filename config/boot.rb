require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

if File.exist? ENV['BUNDLE_GEMFILE']
  require 'bundler'
  begin
    Bundler.setup
  rescue Bundler::GemNotFound => e
    STDERR.puts e.message
    STDERR.puts "Try running `bundle install`."
    exit!
  end 
end
