class DbMigration < ActiveRecord::Migration[6.1]
  def up
    puts "Doing schema migration"
  end

  def down
    puts "Undoing DbMigration"
  end
end
