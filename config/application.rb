require File.expand_path('../boot', __FILE__)

require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

require 'erb'

module Movies
  def self.offline?
    Application.config.offline
  end
  
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    settings = ERB.new(IO.read(File.expand_path('../settings.yml', __FILE__))).result
    mash = Hashie::Mash.new(YAML::load(settings)[Rails.env.to_s])
    
    optional_file = File.expand_path('../settings.local.yml', __FILE__)
    if File.exists? optional_file
      optional_settings = ERB.new(IO.read(optional_file)).result
      optional_values = YAML::load(optional_settings)[Rails.env.to_s]
      mash.update optional_values if optional_values
    end
    
    mash.each do |key, value|
      config.send("#{key}=", value)
    end

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
    
    config.middleware.use Twitter::Login,
      :consumer_key => config.twitter.consumer_key, :secret => config.twitter.secret
    
    config.facebook_client = Facebook::Client.new(config.facebook.app_id, config.facebook.secret,
      :user_fields => %w[link name email website timezone movies])

    # Configure sensitive parameters which will be filtered from the log file.
    # config.filter_parameters << :password
  end
end
