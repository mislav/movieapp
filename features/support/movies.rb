require Rails.root + 'spec/support/fixtures'

World(FixtureLoader)

World Module.new {
  def find_movie(title, options = {})
    Movie.first({:title => title}.update(options)).tap do |movie|
      raise "movie not found" unless movie
    end
  end

  # hack: make `ensure_extended_info` a no-op
  def stub_extended_info(selector, extra = {})
    updated_at = 5.minutes.ago.utc
    selector = { _id: {'$in' => selector.map(&:id)} } if Array === selector

    Movie.collection.update(selector, {
      '$set' => {
        rotten_tomatoes: {updated_at: updated_at},
        tmdb_updated_at: updated_at,
        runtime: 95,
        countries: %w[Sweden],
        directors: ["Stanley Kubrick"]
      }.update(extra)
    }, :multi => true, :safe => true)
  end
}
