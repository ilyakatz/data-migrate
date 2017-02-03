require 'generators/data_migrate'
require 'rails/generators'
require 'rails/generators/migration'

module DataMigrate
  module Generators
    class DataMigrationGenerator < Rails::Generators::NamedBase
      namespace "data_migration"
      include Rails::Generators::Migration

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      def create_data_migration
        set_local_assigns!
        migration_template 'data_migration.rb', "db/data/#{file_name}.rb"
      end

      protected

      attr_reader :migration_action

      def next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def set_local_assigns!
        if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          @migration_action = $1
          @table_name       = $2.pluralize
        end
      end
    end
  end
end
