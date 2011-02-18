# https://gist.github.com/833444
module Mongo
  module Instrumentation
    def self.instrument(clazz, *methods)
      clazz.module_eval do
        methods.each do |m|
          class_eval %{def #{m}_with_instrumentation(*args, &block)
            ActiveSupport::Notifications.instrumenter.instrument "mongo.mongo", :name => "#{m}" do
              #{m}_without_instrumentation(*args, &block)
            end
          end
          }

          alias_method_chain m, :instrumentation
        end
      end
    end

    class Railtie < Rails::Railtie
      initializer "mongo.instrumentation" do |app|
        Mongo::Instrumentation.instrument Mongo::Connection, :send_message, :send_message_with_safe_check, :receive_message
        
        #Mongo::Instrumentation.instrument Mongo::Collection, :find, :save, :insert, :update
        #Mongo::Instrumentation.instrument Mongo::DB, :command

        ActiveSupport.on_load(:action_controller) do
          include Mongo::Instrumentation::ControllerRuntime
        end

        Mongo::Instrumentation::LogSubscriber.attach_to :mongo
      end
    end

    module ControllerRuntime
      extend ActiveSupport::Concern

      protected

      attr_internal :mongo_runtime

      def cleanup_view_runtime
        mongo_rt_before_render = Mongo::Instrumentation::LogSubscriber.reset_runtime
        runtime = super
        mongo_rt_after_render = Mongo::Instrumentation::LogSubscriber.reset_runtime
        self.mongo_runtime = mongo_rt_before_render + mongo_rt_after_render
        runtime - mongo_rt_after_render
      end

      def append_info_to_payload(payload)
        super
        payload[:mongo_runtime] = mongo_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, mongo_runtime = super, payload[:mongo_runtime]
          messages << ("Mongo: %.1fms" % mongo_runtime.to_f) if mongo_runtime
          messages
        end
      end
    end

    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current["mongo_mongo_runtime"] = value
      end

      def self.runtime
        Thread.current["mongo_mongo_runtime"] ||= 0
      end

      def self.reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end

      def mongo(event)
        self.class.runtime += event.duration
      end
    end
  end
end
