# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_base_class_name %>
  disable_ddl_transaction!

  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
