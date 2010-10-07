When /^I go back$/ do
  url = page.driver.current_session.history[-2]
  visit url
end

Rack::Test::Session.class_eval do
  attr_reader :history
  
  alias old_initialize initialize
  def initialize(mock)
    old_initialize(mock)
    @history = []
  end
  
  alias old_process_request process_request
  def process_request(uri, env)
    old_process_request(uri, env).tap do |response|
      @history << last_request.url
    end
  end
  
  alias old_follow_redirect follow_redirect!
  def follow_redirect!
    @history.pop
    old_follow_redirect
  end
end
