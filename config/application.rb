require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

module Movies
  def self.offline?
    Application.config.offline
  end
  
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.from_file 'settings.yml'

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :de

    # Configure generators values
    config.generators do |g|
      g.orm             :mingo
      g.template_engine :erb
      g.test_framework  :rspec, :fixture => false
    end
    
    initializer "MongoDB connect" do
      Mingo.connect(config.mongodb.database || config.mongodb.uri)
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
    
    require 'api_runtime_stats'
    
    initializer "cache logging" do
      ActiveSupport::Notifications.subscribe('request.faraday') do |name, start, ending, _, payload|
        Rails.logger.debug "[Faraday] #{payload[:method].to_s.upcase} #{payload[:url]}"
      end
    end
  end
end
