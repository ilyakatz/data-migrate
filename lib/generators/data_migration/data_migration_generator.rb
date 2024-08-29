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
        migration_template template_path, data_migrations_file_path
      end

      protected

      def set_local_assigns!
        if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          @migration_action = $1
          @table_name       = $2.pluralize
        end
      end

      def template_path
        DataMigrate.config.data_template_path
      end

      def migration_base_class_name
        "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      end

      def data_migrations_file_path
        File.join(data_migrations_path, "#{file_name}.rb")
      end

      # Use the first path in the data_migrations_path as the target directory
      def data_migrations_path
        Array.wrap(DataMigrate.config.data_migrations_path).first
      end
    end
  end
end
