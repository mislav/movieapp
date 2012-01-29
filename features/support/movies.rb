require Rails.root + 'spec/support/fixtures'

World(FixtureLoader)

World Module.new {
  def movies_from_tmdb_fixture(fixture)
    body = read_fixture("tmdb-#{fixture}")
    stub_request(:get, /api.themoviedb.org/).
      to_return(:body => body, :status => 200, :headers => {'content-type' => 'application/json'})

    Tmdb.search('').movies
  end

  def find_movie(title, options = {})
    Movie.first({:title => title}.update(options)).tap do |movie|
      raise "movie not found" unless movie
    end
  end

  # hack: make `ensure_extended_info` a no-op
  def stub_extended_info(selector)
    Movie.collection.update(selector, {
      '$set' => {rotten_tomatoes: {updated_at: 5.minutes.ago.utc}},
      '$unset' => {:tmdb_id => 1}
    }, :multi => true, :safe => true)
  end
}
