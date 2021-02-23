class LateMigration < ActiveRecord::Migration
  def up
    puts "Doing schema LateMigration"
  end

  def down
    puts "Undoing LateMigration"
  end
end
