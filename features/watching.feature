@search
Feature: Marking movies as to-watch or watched

  Background:
    Given the database contains movies with full info from searching for "Terminator"
    And these movies are last watched by @ivana
    And I am on the home page
  
  Scenario: Adding movies to to-watch list
    Then I should see "(1984)" for the movie "The Terminator"
    But I should not see a "Want to watch" button for that movie
    And I should see "Login with Twitter or Facebook" in the navigation
    
    When I login as @mislav with the name "Mislav Marohnić"
    Then I should see "Looks like you're new here." in the title
    
    When I go to the home page
    And I press "Want to watch" for the movie "The Terminator"
    Then I should see 'In your to watch list' for that movie
    When I press "Want to watch" for the movie "Terminator 2: Judgment Day"
    
    When I follow "mislav" in the navigation
    Then I should see "Mislav Marohnić didn't tell us what they watched yet."
    When I follow "2 movies to watch"
    Then I should see movies: "The Terminator (1984)" and "Terminator 2: Judgment Day (1991)"
  
  Scenario: Adding movies to watched list
    Then I should not see an "I watched this" button for the movie "Terminator Salvation"
    
    When I login as @mislav with the name "Mislav Marohnić"
    And I go to the home page
    
    Then I should see an "I watched it" button for the movie "Terminator Salvation"
    When I press "No" for that movie
    Then I should see "You didn't like it" for that movie
    When I press "Yes" for the movie "Terminator 2: Judgment Day"
    And I press "Meh" for the movie "Terminator 3: Rise of the Machines"
    And I follow "mislav" in the navigation
    
    Then I should see movies: "Terminator Salvation (2009)", "Terminator 2: Judgment Day (1991)", and "Terminator 3: Rise of the Machines (2003)"
    Then I should see "You liked it" for the movie "Terminator 2: Judgment Day"
    Then I should see "You thought it was meh" for the movie "Terminator 3: Rise of the Machines"
