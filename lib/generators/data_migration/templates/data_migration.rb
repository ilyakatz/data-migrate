class <%= migration_class_name %> < <%= migration_base_class_name %>
  def self.up
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
