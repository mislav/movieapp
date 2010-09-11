module MoviesHelper
  def link_to_movie(movie)
    link_to(title_for_movie(movie), movie) + movie_year(movie)
  end
  
  def movie_year(movie)
    if movie.year.blank? then ""
    else %( <span class="year">(<time>#{movie.year}</time>)</span>).html_safe
    end
  end
  
  def title_for_movie(movie)
    if movie.original_title and movie.original_title != movie.title
      ("<i>%s</i> / %s" % [h(movie.original_title), h(movie.title.titleize)]).html_safe
    else
      movie.title.titleize
    end
  end
  
  def movie_poster(movie, size = :small)
    src = movie.send(:"poster_#{size}_url")
    width, height = case size
      when :small then [92, 140]
      when :medium then [185, 274]
      end

    if Movies.offline?
      content_tag :span, nil, :class => 'poster', :style => "width:#{width}px; height:#{height}px"
    else
      image_tag src, :width => width, :class => 'poster',
        :alt => src.blank? ? 'No poster' : ('Poster for ' + movie.title)
    end
  end
  
  def movie_runtime(movie)
    if movie.runtime
      hours = movie.runtime / 60
      minutes = movie.runtime % 60
      parts = []
      parts << "<span>#{hours}</span>h" unless hours.zero?
      parts << "<span>#{minutes}</span>m" unless minutes.zero?
      %(<span class="runtime">#{parts.join(' ')}</span>).html_safe
    end
  end
  
  def movie_actions(movie)
    render 'movies/actions', :movie => movie if logged_in?
  end
end
