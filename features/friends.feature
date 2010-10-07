Feature: Discovering movies watched by friends

  Background:
    Given the database contains movies from TMDB "terminator.json" with full info
    And @ivana and @jordi are friends of @mislav
  
  Scenario: New user, nothing watched by friends
    When I login as @mislav
    Then I should not see "movies from friends"
  
  Scenario: Nothing watched by friends
    Given @mislav is not a new user
    When I login as @mislav
    And I follow "movies from friends"
    Then I should see "No movies found."
  
  Scenario: New user, friends watched something
    Given @ivana watched "The Terminator"
    When I login as @mislav
    Then I should see "Your friends have watched 1 movie."
    When I follow "movies from friends"
    Then I should see "The Terminator" as a movie title in the results
  
  Scenario: Friends watched multiple movies
    Given @ivana and @jordi watched "The Terminator"
    And @jordi watched "Terminator Salvation"
    And @mislav is not a new user
    When I login as @mislav
    And I follow "movies from friends"
    And I follow "Terminator Salvation"
    Then I should see "jordi has watched this."
    When I go back
    And I follow "The Terminator"
    Then I should see "jordi and ivana have watched this."
