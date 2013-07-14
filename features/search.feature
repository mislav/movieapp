@search
Feature: Movie search

  Background:
    Given I am on the home page

  Scenario: No results
    When I search for "Lepa Brena"
    Then I should see "Search results for Lepa Brena" in the title
    And I should see "No movies found"

  Scenario: Blank search
    When I search for ""
    Then I should see "error" in the title
    And I should see "You can't enter a blank query"

  Scenario: One result
    When I search for "red shoe diaries"
    Then I should not see "Search results for red shoe diaries" in the title
    But I should see "Red Shoe Diaries (1992)" in the title
    And I should see "Trapped by a burning secret."
    And I should see "by Zalman King"

  Scenario: Multiple results
    When I search for "Terminator"
    And I should see "The Terminator" as a movie title in the results
    And I should see "(1984)" for the movie "The Terminator"
    And I should see "Terminator 2: Judgment Day" as a movie title in the results
    And I should see "Terminator 3: Rise of the Machines" as a movie title in the results
