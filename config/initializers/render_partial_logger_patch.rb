ActiveSupport.on_load(:action_view) do
  ActionView::LogSubscriber.class_eval do
    undef render_partial
    def render_partial event
      render_template event if log_render_partial?
    end

    def log_render_partial?
      logger and logger.level <= ::Logger::DEBUG
    end
  end
end
