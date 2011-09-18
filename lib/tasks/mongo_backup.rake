require 'uri'

namespace :db do
  task :dump, [:path] => :environment do |task, args|
    uri = URI.parse Rails.application.config.mongodb.uri

    dump = ['-u', uri.user, '-p', uri.password]
    dump << '--host' << "#{uri.host}:#{uri.port}"
    dump << '--db' << uri.path.tr('/', '')
    dump << '--out' << (args[:path] || 'db')

    exec 'mongodump', *dump
  end
end
