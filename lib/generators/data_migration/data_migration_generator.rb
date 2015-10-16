require 'generators/data_migrate'
require 'rails/generators'
require 'rails/generators/migration'

module DataMigrate
  module Generators
    class DataMigrationGenerator < Rails::Generators::NamedBase
      namespace "data_migration"
      include Rails::Generators::Migration

      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
      class_option :skip_schema_migration,
                   :aliases => '-m',
                   :desc => 'Dont generate database schema migration file.', :type => :boolean
      class_option :classes,
                   :desc => 'Classes that will be used in the data migration',
                   :type => :array
      class_option :required, :desc => 'Mark this as a "required" migration.'

      def create_data_migration
        if options.required?
          ENV['REQUIRED_DATA_MIGRATIONS'] = 'true'
        end
        set_local_assigns!
        unless options.skip_schema_migration?
          migration_template "migration.rb", "db/migrate/#{file_name}.rb"
        end
        migration_template "data_migration.rb", "#{DataMigrate::DataMigrator.migrations_path}/#{file_name}.rb"
        if options.classes
          options.classes.each do |class_name|
            klass = class_name.constantize
            while klass.superclass != ActiveRecord::Base
              klass = klass.superclass
              unless options.classes.include?(klass.name)
                options.classes.unshift(klass.name)
              end
            end
          end
          migration_template "migration_include.rb",
                             "#{DataMigrate::DataMigrator.migrations_path}/includes/#{file_name}.rb"
        end
      end

      protected
      attr_reader :migration_action

      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
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
