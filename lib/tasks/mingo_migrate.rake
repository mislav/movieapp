require 'mingo_migrations'

namespace :db do
  migrations_dir = Rails.root + 'db/migrate'
  
  task :migrate => :environment do
    migrations = Mingo::Migration.migrations(migrations_dir).select(&:pending?)
    if migrations.empty?
      puts "Nothing to migrate."
    else
      migrations.each do |migration|
        puts "Performing #{migration.name}"
        migration.migrate!
      end
      puts "Done."
    end
  end
  
  namespace :migrate do
    task :status => :environment do
      puts Mingo::Migration.migrations(migrations_dir)
    end
    
    task :redo => :environment do
      last_migration = Mingo::Migration.migration_definitions(migrations_dir).last
      migration = Mingo::Migration.load_migration(last_migration)
      puts "Reverting #{migration.name}"
      migration.revert!
      puts "Performing #{migration.name}"
      migration.migrate!
    end
    
    task :down => :environment do
      last_migration = Mingo::Migration.migration_definitions(migrations_dir).last
      migration = Mingo::Migration.load_migration(last_migration)
      puts "Reverting #{migration.name}"
      migration.revert!
    end
  end
end
