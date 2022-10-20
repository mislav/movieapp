module NeverForget
  class << self
    attr_writer :enabled
    def enabled?() @enabled end
  end
  self.enabled = true

  def self.log(error, env = {}, &block)
    Exception.create(error, env, &block) if enabled?
  rescue
    warn "NeverForget: error saving exception (#{$!.class} #{$!})"
    warn $!.backtrace.first
  end
end

require 'never_forget/exception_handler'
require 'never_forget/exception'
require 'never_forget/railtie'
