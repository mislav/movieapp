require 'will_paginate/page_number'
require 'will_paginate/per_page'

class User::MoviesAssociation
  attr_reader :per_page, :current_page
  
  def initialize(user, property, options)
    @user = user
    @options = options
    @property = property
    @counter_cache_field = "#{@property}_count"
    @per_page = nil
  end
  
  def where(options)
    @options.update options
    @counter_cache_field = nil
    self
  end
  
  def limit(size)
    @per_page = Integer(size)
    self
  end
  
  def page(pagenum)
    @current_page = WillPaginate::PageNumber(pagenum.nil? ? 1 : pagenum)
    @per_page = WillPaginate.per_page if @per_page.nil?
    self
  end
  
  def cache_key
    [@user.cache_key, @property, counter_cache, per_page, @options[:max_id]].to_param
  end
  
  include Enumerable
  
  def each(options = {})
    return to_enum(__method__, options) unless block_given?
    each_with_link(options) { |movie, link| yield movie }
  end
  
  def each_with_link(options = {})
    return to_enum(__method__, options) unless block_given?
    movie_ids = link_documents.map { |doc| doc['movie_id'] }
    Movie.find(movie_ids, options).each_with_index do |movie, idx|
      yield movie, link_documents[idx]
    end
  end
  
  def last_id
    link_doc = link_documents.last and link_doc['_id']
  end
  
  def has_more?
    link_documents
    @has_more
  end
  
  def include?(movie)
    !!link_to_movie(movie)
  end
  
  def <<(movie)
    insert movie_id: movie.id, user_id: @user.id
    self 
  end
  
  def delete(movie)
    if link_doc = link_to_movie(movie)
      collection.remove _id: link_doc['_id']
      change_counter_cache(-1)
      unload_links
      link_doc
    end
  end
  
  def size
    link_documents.size
  end
  
  def empty?
    total_entries.zero? or size.zero?
  end
  
  def count
    find_links(@options.except(:since_id, :max_id)).count
  end
  
  def total_entries
    counter_cache
  end
  
  def reload
    unload_links
    @counter_cache = nil
    self
  end
  
  private
  
  def collection
    @collection ||= @user.class.collection[@property]
  end
  
  def insert(link_doc)
    unless include? link_doc[:movie_id]
      id = collection.save link_doc
      change_counter_cache(1)
      unload_links
      id
    end
  end
  
  def find_links(options = @options)
    selector = { user_id: @user.id }
    if options
      if options[:max_id] or options[:since_id]
        cond = (selector[:_id] = {})
        min = options[:since_id] and cond['$gt'] = BSON::ObjectId[min]
        max = options[:max_id]   and cond['$lt'] = BSON::ObjectId[max]
      end
      selector.update options.except(:since_id, :max_id)
    end
    collection.find(selector, sort: [:_id, -1])
  end
  
  def link_documents_for_movie(movie)
    link_documents.select { |doc| doc['movie_id'] == movie.id }
  end

  def link_to_movie(movie)
    link_documents_for_movie(movie).first
  end
  
  def link_documents
    @link_documents ||= begin
      cursor = find_links
      cursor.limit(per_page + 1) if per_page
      cursor.skip current_page.to_offset(per_page) if current_page
      links = cursor.to_a
      links.pop if @has_more = per_page ? links.size > per_page : false
      links
    end
  end
  public :link_documents
  
  def unload_links
    @link_documents = nil
    @has_more = false
  end
  
  def counter_cache
    @counter_cache ||= if @counter_cache_field
      @user[@counter_cache_field].to_i
    else
      count
    end
  end
  
  def change_counter_cache(by)
    @counter_cache = counter_cache + by
    @user.update '$inc' => { @counter_cache_field => by } if @counter_cache_field
  end
  
  def reset_counter_cache
    return if @counter_cache_field.nil?
    delta = count - counter_cache
    change_counter_cache delta
    counter_cache
  end
  public :reset_counter_cache
  
  def initialize_copy(original)
    @options = @options.dup
    reload
  end
end
