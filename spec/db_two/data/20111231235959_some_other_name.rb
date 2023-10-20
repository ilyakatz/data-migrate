class SomeOtherName < ActiveRecord::Migration[6.1]
  def up
    puts "Doing data migration"
  end

  def down
    puts "Undoing SomeName"
  end
end
