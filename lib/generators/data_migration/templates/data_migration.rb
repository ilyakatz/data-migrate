class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
