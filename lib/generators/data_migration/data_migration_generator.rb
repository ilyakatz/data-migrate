require 'rails/generators/migration'
module DataMigration
  class DataMigrationGenerator < Rails::Generators::NamedBase
    namespace "data_migration"
    argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

    source_root File.expand_path('../templates', __FILE__)
    include Rails::Generators::Migration

    class_option :skip_migration, :desc => 'Dont generate database migration file.', :type => :boolean

    def create_data_migration
      set_local_assigns!
      unless  options.skip_migration?
        migration_template "migration.rb", "db/migrate/#{file_name}.rb"
      end
      migration_template "data_migration.rb", "db/data/#{file_name}.rb"
    end

    protected
    attr_reader :migration_action

    def self.next_migration_number(dirname)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def set_local_assigns!
      if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
        @migration_action = $1
        @table_name       = $2.pluralize
      end
    end
  end
end
