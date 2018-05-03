class DbMigration < ActiveRecord::Migration[5.2]
  def up
    puts "Doing schema migration"
  end

  def down
    puts "Undoing DbMigration"
  end
end
