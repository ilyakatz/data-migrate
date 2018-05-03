class LateMigration < ActiveRecord::Migration[5.2]
  def up
    puts "Doing schema LateMigration"
  end

  def down
    puts "Undoing LateMigration"
  end
end
