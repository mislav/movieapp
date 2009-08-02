class AddNoteToMovies < ActiveRecord::Migration
  def self.up
    add_column :movies, :plot, :text
    add_index :movies, [:title, :year], :unique => true
  end

  def self.down
    remove_index :movies, [:title, :year]
    remove_column :movies, :plot
  end
end
