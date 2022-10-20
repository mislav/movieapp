module NeverForget
  class Railtie < ::Rails::Railtie
    config.never_forget = ActiveSupport::OrderedOptions.new
    config.never_forget.enabled = ::Rails.env.production? || ::Rails.env.staging?
    config.never_forget.list_path = '/_exceptions'

    initializer "never_forget" do |app|
      if NeverForget.enabled = app.config.never_forget.enabled
        app.config.middleware.insert_after 'ActionDispatch::ShowExceptions',
          ExceptionHandler, :list_path => app.config.never_forget.list_path

        ::ActiveSupport.on_load(:action_controller) { include NeverForget::ControllerRescue }
      end
    end
  end
  
  module ControllerRescue
    def rescue_with_handler(exception)
      if super
        # the exception was handled, but we still want to save it
        NeverForget.log(exception, request.env)
        true
      end
    end
  end
end
