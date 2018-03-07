class SomeName < ActiveRecord::Migration
  def up
    puts "Doing data migration"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
