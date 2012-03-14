Feature: Browse by director

  Scenario: Follows director name to see other movies by him
    Given these movies by Lone Scherfig exist:
      | title                       | year |
      | An Education                | 2009 |
      | Another Lone Scherfig movie | 2008 |
      | His third movie             | 2010 |
    When I am on the "An Education" movie page
    And I follow "Lone Scherfig"
    Then I should see "Movies by Lone Scherfig" in the title
    And I should see movies: "His third movie (2010)", "An Education (2009)", and "Another Lone Scherfig movie (2008)"
