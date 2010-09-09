module MoviesHelper
  def link_to_movie(movie)
    link_to(title_for_movie(movie), movie) + movie_year(movie)
  end
  
  def movie_year(movie)
    if movie.year.blank? then ""
    else " <span>(<time>#{movie.year}</time>)</span>".html_safe
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
    width = case size
      when :small then 92
      when :medium then 185
      end

    image_tag src, :width => width, :alt => src.blank? ? 'No cover' : ''
  end
end
