{
  'in the title' => 'h1, h2, h3',
  'as a movie title in the results' => 'ol.movies h1'
}.
each do |within, selector|
  Then /^(?:|I )should( not)? see "([^\"]*)" #{within}$/ do |negate, text|
    with_scope(selector) do
      Then %(I should#{negate} see "#{text}")
    end
  end
end

Then /^I should see an error message: "([^\"]*)"$/ do |text|
  with_scope('.flash-error') do
    Then %(I should see "#{text}")
  end
end
