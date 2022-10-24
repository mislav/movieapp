require 'mingo'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/hash'
require 'rack/request'
require 'rack/utils'

module NeverForget
  class Exception < ::Mingo
    def self.collection_name() "NeverForget" end
    def self.collection
      unless defined? @collection
        db.create_collection collection_name, capped: true, size: 1.megabyte
      end
      super
    end

    include ::Mingo::Timestamps

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

      if env['REQUEST_METHOD']
        self['env'] = sanitized_env
        self['params'] = extract_params
        self['session'] = extract_session
        self['cookies'] = extract_cookies
      else
        self['params'] = clean_unserializable_data(env)
      end
      self
    end

    def request
      @request ||= Rack::Request.new(env)
    end

    def request?
      self['env'].present?
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
      key.to_s.gsub('.', '::').sub(/^\$/, 'DOLLAR::')
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
