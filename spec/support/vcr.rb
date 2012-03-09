require 'vcr'

VCR.configure do |vcr|
  vcr.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  vcr.hook_into :webmock

  vcr.filter_sensitive_data('<TMDB_KEY>') { Movies::Application.config.tmdb.api_key }
  vcr.filter_sensitive_data('<ROTTEN_KEY>') { Movies::Application.config.rotten_tomatoes.api_key }
  vcr.filter_sensitive_data('<NETFLIX_KEY>') { Movies::Application.config.netflix.consumer_key }
end
