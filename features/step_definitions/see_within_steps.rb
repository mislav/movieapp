{
  'in the title' => 'h1, h2, h3',
  'as a movie title in the results' => 'ol.movies h1',
  'in a button' => 'button, input[type=submit]',
  'in the navigation' => 'nav'
}.
each do |within, selector|
  Then /^(.+) #{within}$/ do |step|
    with_scope(selector) do
      Then step
    end
  end
end

Then /^(?:|I )should( not)? see an? "([^\"]*)" button$/ do |negate, text|
  xpath = XPath.css %(input[type=submit][value="#{text}"])
  options = {}
  options[:visible] = true if Capybara.current_driver == Capybara.javascript_driver
  
  if negate.blank?
    page.should have_xpath(xpath, options)
  else
    page.should_not have_xpath(xpath, options)
  end
end

Then /^I should see an error message: "([^\"]*)"$/ do |text|
  with_scope('.flash-error') do
    Then %(I should see "#{text}")
  end
end
