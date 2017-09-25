module MoviesHelper
  def count(collection)
    method = [:total_entries, :size, :count].find { |m| collection.respond_to? m }
    pluralize collection.send(method), 'movie'
  end

  def pluralize_movies(num, suffix = nil)
    suffix = ' ' + suffix if suffix
    (pluralize(num, 'movie') + suffix.to_s).sub(/\d+/, '<span class="num">\0</span>').html_safe
  end
  
  def movie_elsewhere(movie)
    links = []
    if homepage = movie.homepage.presence
      links << ["official website", homepage]
    end
    links << ["Wikipedia", movie.wikipedia_url.presence || [:wikipedia, movie]]
    if imdb_url = movie.imdb_url.presence
      links << ["IMDB", imdb_url]
    end
    if rotten_url = movie.rotten_url.presence
      links << ["Rotten Tomatoes", rotten_url]
      if score = movie.critics_score
        links.last << "Critics score: #{score}%"
      else
        links.last << "No critics score yet"
      end
    end
    if netflix_url = movie.netflix_url.presence
      links << ["Netflix", netflix_url]
    end
    links
  end
  
  def movie_title_with_year(movie, original = false)
    str = original && movie.original_title
    str ||= movie.title
    str += " (#{movie.year})" unless movie.year.blank?
    str
  end
  
  def movie_year(movie)
    if movie.year.blank? then ""
    else %( <span class="year">(<time>#{movie.year}</time>)</span>).html_safe
    end
  end
  
  def movie_plot(movie)
    raw movie.chosen_plot
      .gsub('...', '&#8230;')
      .gsub('--', '&#8212;')
      .gsub("\n", ' ') # avoid http://code.google.com/p/android/issues/detail?id=15067
  end
  
  def movie_poster(movie, size = :small)
    src = movie.send(:"poster_#{size}_url")
    width, height = case size
      when :small then [92, 140]
      when :medium then [185, 274]
      end

    if Movies.offline? or src.blank?
      content_tag :span, nil, :class => 'poster'
    else
      image_tag strip_schema(src), :width => width, :class => 'poster',
        :alt => 'Poster for ' + movie.title
    end
  end
  
  def movie_runtime(movie)
    if movie.runtime
      hours = movie.runtime / 60
      minutes = movie.runtime % 60
      parts = []
      parts << "<span>#{hours}</span>h" unless hours.zero?
      parts << "<span>#{minutes}</span>min" unless minutes.zero?
      %(<span class="runtime">#{parts.join(' ')}</span>).html_safe
    end
  end
  
  def movie_actions(movie)
    render 'movies/actions', :movie => movie
  end
  
  def movie_index_page?
    controller.controller_name == 'movies' and controller.action_name == 'index' and
      !@query and !@director
  end
  
  def movie_show_page?
    controller.controller_name == 'movies' and controller.action_name == 'show'
  end

  def unless_empty(movies)
    yield movies unless movies.empty?
  end

  def blank_slate?
    forced_blank_slate? or @movies.empty?
  end

  def forced_blank_slate?
    params[:blank].present? and Rails.env.development?
  end
end
