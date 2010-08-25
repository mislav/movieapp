require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

require 'erb'

module Movies
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    ERB.new(IO.read(File.expand_path('../settings.yml', __FILE__))).result.tap do |settings|
      Hashie::Mash.new(YAML::load(settings)[Rails.env.to_s]).each do |key, value|
        config.send("#{key}=", value)
      end
    end

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{config.root}/extras )

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

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.orm             :active_record
    #   g.template_engine :erb
    #   g.test_framework  :test_unit, :fixture => true
    # end
    
    initializer "MongoDB connect" do
      Mingo.connect(config.mongodb.database || config.mongodb.uri)
    end
    
    config.middleware.use Twitter::Login,
      :consumer_key => config.twitter.consumer_key, :secret => config.twitter.secret
    
    config.facebook_client = Facebook::Client.new(config.facebook.app_id, config.facebook.secret,
      :user_fields => %w[link name email website timezone movies])

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters << :password
  end
end
