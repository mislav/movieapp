class CreateMembers < ActiveRecord::Migration
  def self.up
    create_table :members do |t|
      t.string :name
      t.timestamps
    end
    
    create_table :roles do |t|
      t.integer :member_id, :movie_id
      t.string :position
      t.timestamps
    end
  end

  def self.down
    drop_table :roles
    drop_table :members
  end
end
