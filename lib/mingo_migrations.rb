require 'mingo'

class Mingo::Migration < Mingo
  property :timestamp
  property :name
  
  attr_reader :description
  
  def migrate(&block)
    @migrate_operation = block
  end
  
  def migrate!
    @migrate_operation.call(self)
    self.save
  end
  
  def revert(&block)
    @revert_operation = block
  end
  
  def revert!
    @revert_operation.call(self)
    # can't call `destroy` because it freezes
    self.class.collection.remove('_id' => self.id)
    self.delete('_id')
  end
  
  def describe(string)
    @description = string.strip.tr("\n", ' ').gsub(/\s{2,}/, ' ')
  end
  
  alias_method :ran?, :persisted?
  
  def pending?
    !ran?
  end
  
  def ran_at
    @ran_at ||= self.id && self.id.generation_time
  end
  
  def to_s
    '[%s] %s: %s' % [timestamp, name, ran? ? 'performed' : 'pending']
  end
  
  def db
    self.class.db
  end
  
  def self.migrations(dir)
    load_migrations(migration_definitions(dir))
  end
  
  class << self
    # used by `define` class method
    attr_accessor :migration_filename, :last_defined_migration
  end
  
  def self.migration_definitions(dir)
    Dir[File.join(dir, '**/*.rb')].select do |name|
      File.basename(name) =~ /^\d+_/
    end.sort
  end
  
  def self.load_migrations(files)
    files.map { |file| load_migration file }
  end
  
  def self.load_migration(filename)
    self.migration_filename = filename
    Kernel.load filename
    self.last_defined_migration
  end
  
  def self.define(&block)
    raise ArgumentError unless self.migration_filename
    timestamp, name = properties_from_filename(self.migration_filename)
    migration = find_or_initialize(timestamp, name)
    migration.instance_eval(&block)
    self.last_defined_migration = migration
  end
  
  def self.find_or_initialize(timestamp, name)
    first(:timestamp => timestamp) || new(:timestamp => timestamp, :name => name)
  end
  
  def self.properties_from_filename(name)
    File.basename(name) =~ /^(\d+)_(.+)\.rb$/ and [$1.to_i, $2]
  end
end
