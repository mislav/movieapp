module ApiRuntimeStats
  module ControllerRuntime
    extend ActiveSupport::Concern

    def redirect_to(*args)
      super.tap do |result|
        self.api_runtimes = ApiRuntimeStats.runtimes.presence
      end
    end

    protected

    attr_internal :api_runtimes

    def cleanup_view_runtime
      runtimes_before = ApiRuntimeStats.runtimes
      runtime = super
      runtimes_after = ApiRuntimeStats.runtimes
      total_after = runtimes_after.values.sum
      
      keys = runtimes_before.keys | runtimes_after.keys
      keys.each { |key| runtimes_after[key] += runtimes_before[key] }
      
      self.api_runtimes = runtimes_after.presence
      runtime - total_after
    end

    def append_info_to_payload(payload)
      super
      payload[:api_runtimes] = self.api_runtimes
    end

    module ClassMethods
      def log_process_action(payload)
        super.tap do |messages|
          if runtimes = payload[:api_runtimes]
            runtimes.each do |host, duration|
              messages << ("#{host}: %.1fms" % (duration * 1000)) if duration > 0
            end
          end
        end
      end
    end
  end
  
  class << self
    attr_accessor :known_keys
  end
  self.known_keys = {}
  
  def self.generate_key(host)
    :"#{self}_#{host}".tap { |key| known_keys[key] = host }
  end
  
  def self.add_duration(host, duration)
    key = generate_key(host)
    Thread.current[key] ||= 0
    Thread.current[key] += duration
  end
  
  def self.runtimes
    known_keys.each_with_object(Hash.new(0)) do |(key, host), times|
      duration = Thread.current[key]
      if duration && duration > 0
        times[host] = duration
        Thread.current[key] = 0
      end
    end
  end
  
  def self.subscribe_to(*args)
    ActiveSupport::Notifications.subscribe(*args) do |name, start, ending, _, payload|
      duration = ending - start
      host = payload[:url].host
      add_duration(host, duration)
    end
  end
  
  ActiveSupport.on_load(:action_controller) do
    include ControllerRuntime
  end
  
  subscribe_to 'request.faraday'
end
