module MoviesHelper
  def link_to_movie(movie)
    link_to(title_for_movie(movie), movie) + " (#{movie.year})"
  end
  
  def title_for_movie(movie)
    if movie.original_title
      "<i>#{movie.original_title}</i> / #{movie.title.titleize}"
    else
      movie.title.titleize
    end
  end
end
