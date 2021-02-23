class DbMigration < ActiveRecord::Migration
  def up
    puts "Doing schema migration"
  end

  def down
    puts "Undoing DbMigration"
  end
end
