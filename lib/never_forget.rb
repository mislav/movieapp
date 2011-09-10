require 'rbconfig'
require 'mingo'
require 'erubis'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash'
require 'rack/request'

module NeverForget
  def self.log(error, env)
    Exception.create(error, env)
  rescue
    warn "NeverForget: error saving exception (#{$!.class} #{$!})"
    warn $!.backtrace.first
  end

  class ExceptionHandler
    TEMPLATE_FILE = File.expand_path('../never_forget.erb', __FILE__)

    def initialize(app)
      @app = app
    end

    def forward(env)
      begin
        @app.call(env)
      rescue StandardError, ScriptError => error
        NeverForget.log(error, env)
        raise error
      end
    end

    def call(env)
      if env['PATH_INFO'] == '/_exceptions'
        body = render_exceptions_view
        [200, {'content-type' => 'text/html'}, [body]]
      else
        forward(env)
      end
    end
    
    def render_exceptions_view
      template = Erubis::Eruby.new(exceptions_template)
      context = Erubis::Context.new(:recent => Exception.recent)
      context.extend TemplateHelpers
      template.evaluate(context)
    end
    
    def exceptions_template
      File.read(TEMPLATE_FILE)
    end
  end

  module TemplateHelpers
    include RbConfig
    extend ActiveSupport::Memoizable

    def gem_path
      paths = []
      paths << Bundler.bundle_path << Bundler.user_bundle_path if defined? Bundler
      paths << Gem.path if defined? Gem
      paths.flatten.uniq
    end

    SYSDIRS = %w[ vendor site rubylib arch sitelib sitearch vendorlib vendorarch top ]

    def system_path
      SYSDIRS.map { |name| CONFIG["#{name}dir"] }.compact
    end

    def external_path
      ['/usr/ruby1.9.2', '/home/heroku_rack', gem_path, system_path].flatten.uniq
    end
    memoize :external_path

    def collapse_line?(line)
      external_path.any? {|p| line.start_with? p }
    end

    def ignore_line?(line)
      line.include? '/Library/Application Support/Pow/'
    end

    def strip_root(line)
      if line =~ %r{/gems/([^/]+)-(\d[\w.]*)/}
        gem_name, gem_version = $1, $2
        path = line.split($&, 2).last
        "#{gem_name} (#{gem_version}) #{path}"
      elsif path = "#{root_path}/" and line.start_with? path
        line.sub(path, '')
      else
        line
      end
    end

    def root_path
      if defined? Bundler then Bundler.root
      elsif defined? Rails then Rails.root
      elsif defined? Sinatra::Application then Sinatra::Application.root
      else Dir.pwd
      end
    end
    memoize :root_path
  end

  module ControllerRescue
    def rescue_with_handler(exception)
      if super
        # the exception was handled, but we still want to save it
        NeverForget.log(exception, request.env)
      end
    end
  end

  ::ActiveSupport.on_load(:action_controller) { include NeverForget::ControllerRescue }

  class Exception < Mingo
    def self.collection_name() "NeverForget" end
    def self.collection
      unless defined? @collection
        db.create_collection collection_name, capped: true, size: 1.megabyte
      end
      super
    end

    extend ActiveSupport::Memoizable
    include Mingo::Timestamps

    def self.create(error, env)
      if connected?
        record = new.init(error, env)
        yield record if block_given?
        record.save
        record
      end
    end

    def self.recent
      find.sort('$natural', :desc).limit(20)
    end

    KEEP = %w[rack.url_scheme action_dispatch.remote_ip]
    EXCLUDE = %w[HTTP_COOKIE QUERY_STRING SERVER_ADDR]
    KNOWN_MODULES = %w[
      ActiveSupport::Dependencies::Blamable
      JSON::Ext::Generator::GeneratorMethods::Object
      ActiveSupport::Dependencies::Loadable
      PP::ObjectMixin
      Kernel
    ]

    attr_reader :exception, :env

    def init(ex, env_hash)
      @exception = unwrap_exception(ex)
      @env = env_hash
      self['name'] = exception.class.name
      self['modules'] = tag_modules
      self['backtrace'] = exception.backtrace.join("\n")
      self['message'] = exception.message

      self['env'] = sanitized_env
      self['params'] = extract_params
      self['session'] = extract_session
      self['cookies'] = extract_cookies
      self
    end

    def request
      @request ||= Rack::Request.new(env)
    end

    def request_url
      env = self['env']
      scheme = env['rack::url_scheme']
      host, port = env['HTTP_HOST'], env['SERVER_PORT'].to_i
      host += ":#{port}" if 'http' == scheme && port != 80 or 'https' == scheme && port != 443

      url = scheme + '://' + File.join(host, env['SCRIPT_NAME'], env['PATH_INFO'])
      url << '?' << Rack::Utils::build_nested_query(self['params']) if get_request? and self['params'].present?
      url
    end

    def request_method
      self['env']['REQUEST_METHOD']
    end

    def get_request?
      'GET' == request_method
    end

    def xhr?
      self['env']['HTTP_X_REQUESTED_WITH'] =~ /XMLHttpRequest/i
    end

    def remote_ip
      self['env']['action_dispatch::remote_ip'] || self['env']['REMOTE_ADDR']
    end

    def tag_modules
      Array(exception.singleton_class.included_modules).map(&:to_s) - KNOWN_MODULES
    end
    memoize :tag_modules

    def unwrap_exception(exception)
      if exception.respond_to?(:original_exception)
        exception.original_exception
      elsif exception.respond_to?(:continued_exception)
        exception.continued_exception
      else
        exception
      end
    end

    def extract_session
      if session = env['rack.session']
        session_hash = session.to_hash.stringify_keys.except('session_id', '_csrf_token')
        clean_unserializable_data session_hash
      end
    end

    def exclude_params
      Array(env['action_dispatch.parameter_filter']).map(&:to_s)
    end
    memoize :exclude_params

    def extract_params
      if params = request.params and params.any?
        filtered = params.each_with_object({}) { |(key, value), keep|
          keep[key] = exclude_params.include?(key.to_s) ? '[FILTERED]' : value
        }
        clean_unserializable_data filtered.except('utf8')
      end
    end

    def extract_cookies
      if cookies = env['rack.request.cookie_hash']
        if options = env['rack.session.options']
          cookies = cookies.except(options[:key])
        end
        clean_unserializable_data cookies
      end
    end

    def sanitized_env
      clean_unserializable_data env.select { |key, _| keep_env? key }
    end

    def keep_env?(key)
      ( key !~ /[a-z]/ or KEEP.include?(key) ) and not discard_env?(key)
    end

    def discard_env?(key)
      EXCLUDE.include?(key) or
        ( key == 'REMOTE_ADDR' and env['action_dispatch.remote_ip'] )
    end

    def sanitize_key(key)
      key.gsub('.', '::').sub(/^\$/, 'DOLLAR::')
    end

    def clean_unserializable_data(data, stack = [])
      return "[possible infinite recursion halted]" if stack.any?{|item| item == data.object_id }

      if data.respond_to?(:to_hash)
        data.to_hash.each_with_object({}) do |(key, value), result|
          result[sanitize_key(key)] = clean_unserializable_data(value, stack + [data.object_id])
        end
      elsif data.respond_to?(:to_ary)
        data.collect do |value|
          clean_unserializable_data(value, stack + [data.object_id])
        end
      else
        data.to_s
      end
    end
  end
end
