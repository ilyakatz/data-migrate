<% if options.classes.present? %>require_relative '<%= "includes/#{@migration_number}_#{@migration_file_name}.rb" %>'
<% end %>
class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
  end

  def self.down
    raise <%= defined?(IrreversibleMigration) ? 'IrreversibleMigration' : 'ActiveRecord::IrreversibleMigration' %>
  end
end
