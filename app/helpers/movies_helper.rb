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
end
