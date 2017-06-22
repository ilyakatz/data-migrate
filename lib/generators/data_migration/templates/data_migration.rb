class <%= migration_class_name %> < <%= migration_base_class_name %>
  def  up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end