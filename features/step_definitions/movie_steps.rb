When /^I search for "([^"]*)"$/ do |query|
  When %(I fill in "#{query}" for "Movie search")
  When %(I press "search")
end

When /^(.+) for the movie "([^"]+)"$/ do |step, title|
  within ".movie:has(a h1:contains('#{title}'))" do
    Then step
  end
end