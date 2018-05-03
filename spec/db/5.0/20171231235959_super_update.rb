class SuperUpdate < ActiveRecord::Migration[5.0]
  def up
    puts "Doing data migration"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
