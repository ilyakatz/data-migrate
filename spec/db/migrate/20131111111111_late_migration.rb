class LateMigration < ActiveRecord::Migration[6.1]
  def up
    puts "Doing schema LateMigration"
  end

  def down
    puts "Undoing LateMigration"
  end
end
