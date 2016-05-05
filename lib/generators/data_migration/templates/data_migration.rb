class <%= migration_class_name %> < ActiveRecord::Migration
  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
