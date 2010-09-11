Feature: Browse by director

  Scenario: Follows director name to see other movies by him
    Given there are three movies by Lone Scherfig
    When I am on the "An Education" movie page
    And I follow "Lone Scherfig"
    Then I should see "Movies by Lone Scherfig" in the title
    And I should see movies: "His Third Movie (2010)", "An Education (2009)", and "Another Lone Scherfig Movie (2008)"
