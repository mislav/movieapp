Feature: Movie search

  Background:
    Given TMDB returns nothing for the terms "Lepa Brena"
    And TMDB returns "black_cat.json" for the terms "Black Cat"

  Scenario: No results
    When I go to the home page
    And I fill in "Lepa Brena" for "Movie search"
    And I press "search"
    Then I should see "Search results for Lepa Brena" in the title
    And I should see "Nothing found."

  Scenario: One result
    When I go to the home page
    And I fill in "Black Cat" for "Movie search"
    And I press "search"
    Then I should see "Search results for Black Cat" in the title
    And I should see "Black Cat, White Cat" as a movie title in the results
    But I should not see "Nothing found."
