class AddMoviesYearIndex < ActiveRecord::Migration
  def self.up
    add_index :movies, :year
    add_index :movies, :title
  end

  def self.down
    remove_index :movies, :title
    remove_index :movies, :year
  end
end
