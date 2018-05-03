class LateMigration < ActiveRecord::Migration[5.0]
  def up
    puts "Doing schema LateMigration"
  end

  def down
    puts "Undoing LateMigration"
  end
end
