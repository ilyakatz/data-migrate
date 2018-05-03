class SomeName < ActiveRecord::Migration[5.2]
  def up
    puts "Doing data migration"
  end

  def down
    puts "Undoing SomeName"
  end
end
