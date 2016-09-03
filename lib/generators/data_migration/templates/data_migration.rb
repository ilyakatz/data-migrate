class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    # Add migration code here
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
