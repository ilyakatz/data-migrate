class SomeName < ActiveRecord::Migration[6.0]
  def up
    puts "Doing data migration"
  end

  def down
    puts "Undoing SomeName"
  end
end
