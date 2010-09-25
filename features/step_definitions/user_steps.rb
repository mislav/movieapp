When /^I login as @(\w+) with the name "([^"]+)"$/ do |username, name|
  Rails.configuration.twitter.test_user = {
    'screen_name' => username, 'name' => name, 'id' => 1234
  }
  visit instant_login_path
end