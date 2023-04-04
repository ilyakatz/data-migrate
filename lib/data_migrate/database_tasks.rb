# frozen_string_literal: true

require "data_migrate/config"

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    class << self
      def schema_file_type(_format = nil)
        "data_schema.rb"
      end

      def dump_filename(db_config_name, format = ActiveRecord::Base.schema_format) # db_config
        filename = if db_config_name == "primary" # db_config.name
          schema_file_type(format)
        else
          "#{db_config_name}_#{schema_file_type(format)}"
        end

        ENV["DATA_SCHEMA"] || File.join(db_dir, filename)
      end

      def check_schema_file(filename)
        unless File.exist?(filename)
          message = +%{#{filename} doesn't exist yet. Run `rake data:migrate` to create it, then try again.}
          Kernel.abort message
        end
      end

      def pending_migrations
        sort_migrations(pending_schema_migrations, pending_data_migrations)
      end

      def sort_migrations(*migrations)
        migrations.flatten.sort { |a, b|  sort_string(a) <=> sort_string(b) }
      end

      def sort_string(migration)
        "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
      end

      def data_migrations_path
        ::DataMigrate.config.data_migrations_path
      end

      def run_migration(migration, direction)
        if migration[:kind] == :data
          ::ActiveRecord::Migration.write("== %s %s" % ["Data", "=" * 71])
          ::DataMigrate::DataMigrator.run(direction, data_migrations_path, migration[:version])
        else
          ::ActiveRecord::Migration.write("== %s %s" % ["Schema", "=" * 69])
          ::DataMigrate::SchemaMigration.run(direction, ::DataMigrate::SchemaMigration.migrations_paths, migration[:version])
        end
      end

      def forward(step = 1)
        DataMigrate::DataMigrator.assure_data_schema_table
        migrations = pending_migrations.reverse.pop(step).reverse
        migrations.each do | pending_migration |
          if pending_migration[:kind] == :data
            ActiveRecord::Migration.write("== %s %s" % ["Data", "=" * 71])
            DataMigrate::DataMigrator.run(:up, data_migrations_path, pending_migration[:version])
          elsif pending_migration[:kind] == :schema
            ActiveRecord::Migration.write("== %s %s" % ["Schema", "=" * 69])
            DataMigrate::SchemaMigration.run(:up, DataMigrate::SchemaMigration.migrations_paths, pending_migration[:version])
          end
        end
      end

      def pending_data_migrations
        data_migrations = DataMigrate::DataMigrator.migrations(data_migrations_path)
        sort_migrations(DataMigrate::DataMigrator.new(:up, data_migrations ).
          pending_migrations.map {|m| { version: m.version, name: m.name, kind: :data }})
      end

      def pending_schema_migrations
        ::DataMigrate::SchemaMigration.pending_schema_migrations
      end

      def past_migrations(sort = nil)
        data_versions = DataMigrate::DataSchemaMigration.table_exists? ? DataMigrate::DataSchemaMigration.normalized_versions : []
        schema_versions = ActiveRecord::SchemaMigration.normalized_versions
        migrations = data_versions.map { |v| { version: v.to_i, kind: :data } } + schema_versions.map { |v| { version: v.to_i, kind: :schema } }

        sort&.downcase == "asc" ? sort_migrations(migrations) : sort_migrations(migrations).reverse
      end
    end
  end
end
