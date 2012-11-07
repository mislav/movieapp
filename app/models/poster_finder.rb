module PosterFinder
  def self.medium_width() 185 end
  def self.small_width()   92 end

  def self.call movie
    tmdb_config = Tmdb.configuration
    tmdb_images = Tmdb.poster_images movie.tmdb_id

    # sort by language ("en" and nil first) then average rating
    tmdb_images.sort! { |a, b|
      if a.language == b.language
        a.average_rating <=> b.average_rating
      else
        a.language == 'en' || (a.language.nil? && b.language != 'en') ? 1 : -1
      end
    }
    tmdb_images.reverse!

    tmdb_images.map do |image|
      Poster.new \
        tmdb_config.poster_url(medium_width * 2, image.file_path),
        tmdb_config.poster_url(small_width * 2, image.file_path)
    end
  end

  Poster = Struct.new(:medium_url, :small_url)
end
