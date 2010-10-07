Feature: Movie search

  Background:
    Given TMDB returns nothing for the terms "Lepa Brena"
    And TMDB returns "black_cat.json" for the terms "Black Cat"
    And TMDB returns "terminator.json" for the terms "The Terminator"
    And I am on the home page

  Scenario: No results
    When I search for "Lepa Brena"
    Then I should see "Search results for Lepa Brena" in the title
    And I should see "Nothing found."

  Scenario: One result
    When I search for "Black Cat"
    Then I should see "Search results for Black Cat" in the title
    And I should see "Black Cat, White Cat" as a movie title in the results
    But I should not see "Nothing found."
    
    Given TMDB returns "black_cat-full.json" for "Black Cat, White Cat" movie details
    
    When I follow "Black Cat, White Cat"
    Then I should see "Crna mačka, beli mačor" in the title
    And I should see "Dadan has a sister, Afrodita, that he desperately wants to see get married"
    And I should see "by Emir Kusturica"

  Scenario: Multiple results
    When I search for "The Terminator"
    And I should see "The Terminator" as a movie title in the results
    And I should see "(1984)" for the movie "The Terminator"
    But I should not see "Steven Spielberg gives us a humorous look" for the movie "The Terminator"
    And I should see "Terminator 2: Judgment Day" as a movie title in the results
    And I should see "Terminator 3: Rise of the Machines" as a movie title in the results
