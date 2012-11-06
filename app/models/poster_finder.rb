module PosterFinder
  def self.medium_width() 185 end
  def self.small_width()   92 end

  def self.call movie
    tmdb_config = Tmdb.configuration
    tmdb_images = Tmdb.poster_images movie.tmdb_id

    Rails.logger.debug "found %d poster images" % tmdb_images.size

    tmdb_images.sort_by {|image| image.average_rating }.reverse.map do |image|
      Poster.new \
        tmdb_config.poster_url(medium_width * 2, image.file_path),
        tmdb_config.poster_url(small_width * 2, image.file_path)
    end
  end

  Poster = Struct.new(:medium_url, :small_url)
end
