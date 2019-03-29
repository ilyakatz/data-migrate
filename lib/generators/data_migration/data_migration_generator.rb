require "generators/data_migrate"
require "rails/generators"
require "rails/generators/active_record/migration"
require "rails/generators/migration"
require "data_migrate/config"

module DataMigrate
  module Generators
    class DataMigrationGenerator < Rails::Generators::NamedBase
      namespace "data_migration"
      include ActiveRecord::Generators::Migration

      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def create_data_migration
        set_local_assigns!
        call_migration!
      end

      protected

      def call_migration!
        if file_name == 'initialize'
          migration_template "initializer_migration.rb", "db/migrate/create_data_migrations.rb"
        else
          migration_template "data_migration.rb", "#{data_migrations_path}#{file_name}.rb"
        end
      end

      def set_local_assigns!
        if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          @migration_action = $1
          @table_name       = $2.pluralize
        end
      end

      def migration_base_class_name
        if ActiveRecord.version >= Gem::Version.new("5.0")
          "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
        elsif ActiveRecord.version >= Gem::Version.new("5.2")
          "DataMigrate::MigrationContext"
        else
          "ActiveRecord::Migration"
        end
      end

      def data_migrations_path
        DataMigrate.config.data_migrations_path
      end
    end
  end
end
