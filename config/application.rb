require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

if defined?(Bundler)
  Bundler.require(:default, :assets, Rails.env)
end

module Movies
  def self.offline?
    Application.config.offline
  end
  
  class Application < Rails::Application
    config.from_file 'settings.yml'

    # default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Configure generators values
    config.generators do |g|
      g.orm             :mingo
      g.template_engine :erb
      g.test_framework  :rspec, :fixture => false
    end
    
    initializer "MongoDB connect" do
      Mingo.connect config.mongodb.database || config.mongodb.uri,
        logger: Rails.env.development? && Rails.logger
    end
    
    config.twitter_login = Twitter::Login.new \
      :consumer_key => config.twitter.consumer_key, :secret => config.twitter.secret
    
    config.facebook_client = Facebook::Client.new(config.facebook.app_id, config.facebook.secret,
      :user_fields => %w[link name email website timezone])

    # Configure sensitive parameters which will be filtered from the log file.
    # config.filter_parameters << :password
    
    unless Rails.env.development?
      # this seems to be the only place to hook into the phase when routes are loaded
      initializer "User reserved names", :after => :set_routes_reloader do 
        User.apply_reserved_names_from_routes
      end
    end
    
    initializer "model cache" do
      require 'cache'
      Cache.perform_caching = Rails.env.production?
    end
    
    require 'api_runtime_stats'
    
    initializer "cache logging" do
      if "script/rails" == $0
        ActiveSupport::Notifications.subscribe('request.faraday') do |name, start, ending, _, payload|
          puts "[Faraday] #{payload[:method].to_s.upcase} #{payload[:url]}"
        end
      else
        ActiveSupport::Notifications.subscribe('request.faraday') do |name, start, ending, _, payload|
          Rails.logger.debug "[Faraday] #{payload[:method].to_s.upcase} #{payload[:url]}"
        end
      end
    end

    require 'never_forget'
    if NeverForget.enabled = config.store_exceptions
      config.middleware.use NeverForget::ExceptionHandler
    end
  end
end
