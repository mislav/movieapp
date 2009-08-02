require 'imdb_import'

importer = ImdbImport.new('running-times', :lines_to_skip => 14)

importer.process do |title_string, running_time_string, note|
  importer.process_title(title_string) do |title, year|
    running_time = running_time_string =~ /\d+/ && $&.to_i
    
    unless running_time.nil? or (note and note =~ /episode|commercial/) or running_time_string =~ /\d\s*x\s*\d/
      sql = "UPDATE movies SET length = #{running_time} WHERE title = %s AND year = %d;" % [importer.connection.quote(title), year]
      puts sql
      true
    end
  end
end

p importer.processed_count
