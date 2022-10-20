require 'rbconfig'
require 'erubis'
require 'yaml'

module NeverForget
  class ExceptionHandler
    TEMPLATE_FILE = File.expand_path('../list_exceptions.erb', __FILE__)

    def initialize(app, options = {})
      @app = app
      @options = {:list_path => '/_exceptions'}.update(options)
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
      if env['PATH_INFO'] == File.join('/', @options[:list_path])
        begin
          body = render_exceptions_view
          [200, {'content-type' => 'text/html'}, [body]]
        rescue
          [500, {'content-type' => 'text/plain'}, ["%s: %s\n\n%s" % [
            $!.class.name,
            $!.message,
            $!.backtrace.join("\n")
          ]]]
        end
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

    def y(obj)
      YAML.dump(obj).sub(/^---.*\n/, '').gsub(/ !(omap|map:BSON::OrderedHash) *$/, '')
    end

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
      ['/usr/ruby1.9.2', '/home/heroku_rack', gem_path, system_path].flatten.uniq.map(&:to_s)
    end

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
  end
end
