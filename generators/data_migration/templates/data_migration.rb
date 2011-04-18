class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise IrreversibleMigration
  end
end
