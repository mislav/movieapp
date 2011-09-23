module HistoryManagement
  def go_back
    visit browser.previous_url
  end
end

module BrowserHistory
  def history
    @history = [] unless defined?(@history)
    @history
  end

  def previous_url
    history[-2] or raise "can't go back in history"
  end

  [:get, :post, :put, :patch, :delete].each do |method|
    define_method(method) { |path, attributes, env|
      result = super(path, attributes, env)
      history << path unless result.redirect?
      result
    }
  end
end

Capybara::RackTest::Driver.class_eval do
  include HistoryManagement
end

Capybara::RackTest::Browser.class_eval do
  include BrowserHistory
end
