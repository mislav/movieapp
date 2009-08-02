require 'imdb_import'

importer = ImdbImport.new('movies', :lines_to_skip => 15)

importer.process do |title_string|
  importer.process_title(title_string) do |title, year|
    values = [title, year].collect { |value| importer.connection.quote(value) }
    sql = "INSERT INTO movies (title, year) VALUES(#{values.join(', ')});"
    # importer.connection.insert sql
    puts sql
    true
  end
end

p importer.processed_count
