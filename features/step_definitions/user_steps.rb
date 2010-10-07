When /^I login as @(\w+)(?: with the name "([^"]+)")?$/ do |username, name|
  user = find_or_create_user(username, :name => name)
  
  Rails.configuration.twitter.test_user = {
    'screen_name' => username, 'id' => user['twitter']['id']
  }
  visit instant_login_path
end

Given /^(@.+) are friends of @([^@]+)$/ do |users, username|
  main = find_or_create_user(username)
  twitter_ids = []
  
  each_user(users, true) do |user|
    twitter_ids << user['twitter']['id']
  end
  
  main.twitter_friends = twitter_ids
  main.save
end

Given /^@([^@]+) is not a new user$/ do |username|
  user = find_or_create_user(username)
  user.watched << Movie.first
end