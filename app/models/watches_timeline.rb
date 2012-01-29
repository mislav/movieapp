require 'will_paginate/page_number'
require 'will_paginate/per_page'

# Paginated timeline of movies watched by users.
# Aggregates several users that have watched the same movie in a single page.
# Exposes methods to find out movie ratings by these users.
#
# Acts as a paginated Enumerable, in some things also like an Array.
class WatchesTimeline
  def self.collection
    User.collection['watched']
  end
  
  def self.create(selector = {}, options = {})
    if options[:max_id] or options[:since_id]
      selector = {:_id => {}}.merge(selector)
      selector[:_id]['$gt'] = BSON::ObjectId[options[:since_id]] if options[:since_id]
      selector[:_id]['$lt'] = BSON::ObjectId[options[:max_id]] if options[:max_id]
    end
    new collection.find(selector, :sort => [:_id, -1])
  end
  
  include Enumerable
  
  USER_FIELDS = %w[username name twitter_picture twitter.screen_name facebook.id]
  
  attr_reader :current_page, :per_page
  
  def initialize(watched_cursor)
    @watched_cursor = watched_cursor
    @current_page = WillPaginate::PageNumber(1)
    @per_page = WillPaginate.per_page
    @has_more = false
  end
  
  def limit(num)
    @per_page = num.to_i
    @watched_cursor.batch_size(@per_page * 2)
    self
  end
  
  def page(pagenum)
    @current_page = WillPaginate::PageNumber(pagenum.nil? ? 1 : pagenum)
    self
  end
  
  def has_more?
    load_movies
    @has_more
  end
  
  def last_id
    watch = @watches.last and watch['_id'] if defined? @watches
  end
  
  def each
    return to_enum unless block_given?
    load_movies.each(&Proc.new)
  end
  
  def people_who_watched(movie)
    user_ids(:movie_id => movie.id).map { |id| people[id] }
  end
  
  def rating_for(movie, user)
    watches(movie_id: movie.id, user_id: user.id).first['liked']
  end
  
  def offset
    current_page.to_offset(per_page)
  end
  
  def size
    cursor = load_movies
    cursor.selector[:_id]['$in'].size
  end
  alias length size
  
  def empty?
    size.zero?
  end
  
  # FIXME: this sucks so much
  def total_entries
    @total_entries ||= begin
      @watched_cursor.rewind!
      @watched_cursor.map {|w| w['movie_id'] }.uniq.size
    end
  end
  
  def total_pages
    (total_entries / per_page) + 1
  end
  
  private
  
  def watches(filters = nil)
    load_movies
    if filters
      @watches.select { |w| filters.all? {|k,v| w[k.to_s] == v } }
    else
      @watches
    end
  end
  
  def load_movies
    return @movies if defined? @movies
    done_page = 0
    movie_ids = []
    @watches  = []
    
    @watched_cursor.each do |watch|
      movie_id = watch['movie_id']
      unless movie_ids.include? movie_id
        if movie_ids.size == per_page
          if (done_page += 1) == current_page
            @has_more = @watched_cursor.has_next?
            break # we're done
          else
            # start filling in a fresh page
            movie_ids.clear
            @watches.clear
          end
        end
        movie_ids << movie_id
      end
      @watches << watch
    end
    
    @movies = Movie.find(movie_ids)
  end
  
  def user_ids(filters = nil)
    watches(filters).map {|w| w['user_id'] }.uniq
  end
  
  def people
    @people ||= User.find(user_ids, fields: USER_FIELDS).index_by(&:id)
  end
end
