require 'active_record'

class ImdbImport
  
  attr_reader :connection, :processed_count
  
  def initialize(source, options = {})
    @source_filename = "tmp/IMDB/#{source}.list"
    @lines_to_skip = options[:lines_to_skip] || 0
    @stop_after = options[:stop_after]
    @processed_count = 0
  end
  
  SEPARATOR = /\A-{70,}/
  BLANK = "\n"
  TITLE_REGEX = /(.+) \((\d+(?:\/[A-Z]+)?|\?+)\)(?: \((TV|V|VG)\))?\Z/
  
  def process(&block)
    setup_connection
    
    File.open(@source_filename) do |file|
      @ignoring = false

      file.each_line do |line|
        next if @ignoring

        unless @lines_to_skip.zero?
          @lines_to_skip -= 1
          next
        end
        
        begin
          process_line(line, &block)
        rescue
          $stderr.puts "error processing line #{file.lineno}: #{line.inspect}"
          raise
        end
        
        break if @stop_after and @processed_count > @stop_after
      end
    end
  end

  def process_title(line)
    unless line =~ TITLE_REGEX
      raise ArgumentError, "#{line.inspect} doesn't look like a title"
    end
    
    title = $1
    year = $2.to_i
    type = $3

    if year > 0 and type != 'VG' and type != 'V'
      yield title, year
    end
  end
  
  def connection
    @connection ||= setup_connection
  end
  
  protected
  
  def process_line(line)
    case line
    when BLANK
      # skip
    when SEPARATOR
      @ignoring = true
    else
      unless line.index('{')
        columns = line.chomp.split(/\t+/)
        @processed_count += 1 if yield *columns
      end
    end
  end
  
  def setup_connection
    ActiveRecord::Base.configurations = YAML.load open('config/database.yml')
    ActiveRecord::Base.establish_connection 'development'
    ActiveRecord::Base.connection
  end
  
end
