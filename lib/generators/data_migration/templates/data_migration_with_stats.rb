require_relative './helpers'
class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    print_memory_usage do
      print_time_spent do
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
