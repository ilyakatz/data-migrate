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

      def dump_filename(namespace, format = ActiveRecord::Base.schema_format)
        filename = if namespace == "primary"
          schema_file_type(format)
        else
          "#{namespace}_#{schema_file_type(format)}"
        end

        ENV["DATA_SCHEMA"] || File.join(schema_location, filename)
      end

      def schema_dump_path(db_config, format = ActiveRecord.schema_format)
        return ENV["DATA_SCHEMA"] if ENV["DATA_SCHEMA"]

        filename = if db_config.primary?
          schema_file_type(format)
        else
          [db_config.name, schema_file_type(format)].join("_")
        end

        return unless filename

        File.dirname(filename) == schema_location ? filename : File.join(schema_location, filename)
      end

      def schema_location
        db_dir
      end

      def check_schema_file(filename)
        unless File.exist?(filename)
          message = +%{#{filename} doesn't exist yet. Run `rake data:migrate` to create it, then try again.}
          Kernel.abort message
        end
      end

      def pending_migrations
        sort_migrations(
          pending_schema_migrations,
          pending_data_migrations
        )
      end

      def sort_migrations set_1, set_2=nil
        migrations = set_1 + (set_2 || [])
        migrations.sort{|a,b|  sort_string(a) <=> sort_string(b)}
      end

      def sort_string migration
        "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
      end

      def data_migrations_path
        ::DataMigrate.config.data_migrations_path
      end

      def run_migration(migration, direction)
        ActiveRecord::Base.descendants.each(&:reset_column_information)

        if migration[:kind] == :data
          ::ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          ::DataMigrate::DataMigrator.run(direction, data_migrations_path, migration[:version])
        else
          ::ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
          ::DataMigrate::SchemaMigration.run(
            direction,
            ::DataMigrate::SchemaMigration.migrations_paths,
            migration[:version]
          )
        end
      end
    end

    # This overrides ActiveRecord::Tasks::DatabaseTasks
    def self.schema_file(_format = nil)
      File.join(db_dir, "data_schema.rb")
    end

    def self.forward(step = 1)
      DataMigrate::DataMigrator.assure_data_schema_table
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
        ActiveRecord::Base.descendants.each(&:reset_column_information)

        if pending_migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ["Data", "=" * 71])
          DataMigrate::DataMigrator.run(:up, data_migrations_path, pending_migration[:version])
        elsif pending_migration[:kind] == :schema
          ActiveRecord::Migration.write("== %s %s" % ["Schema", "=" * 69])
          DataMigrate::SchemaMigration.run(:up, schema_migrations_path, pending_migration[:version])
        end
      end
    end

    def self.data_migrations_path
      DataMigrate.config.data_migrations_path
    end

    def self.schema_migrations_path
      "db/migrate/"
    end

    def self.pending_migrations
      sort_migrations(pending_schema_migrations, pending_data_migrations)
    end

    def self.pending_data_migrations
      data_migrations = DataMigrate::DataMigrator.migrations(data_migrations_path)
      sort_migrations(DataMigrate::DataMigrator.new(:up, data_migrations ).
        pending_migrations.map {|m| { version: m.version, name: m.name, kind: :data }})
    end

    def self.pending_schema_migrations
      ::DataMigrate::SchemaMigration.pending_schema_migrations
    end

    def self.sort_migrations(set1, set2 = nil)
      migrations = set1 + (set2 || [])
      migrations.sort {|a, b|  sort_string(a) <=> sort_string(b)}
    end

    def self.sort_string(migration)
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end

    def self.past_migrations(sort = nil)
      sort = sort.downcase if sort
      db_list_data =
        if DataMigrate::DataSchemaMigration.table_exists?
          DataMigrate::DataSchemaMigration.normalized_versions.sort
        else
          []
        end
      db_list_schema = ActiveRecord::SchemaMigration.normalized_versions.sort.sort
      migrations = db_list_data.map do |d|
        {
          version: d.to_i, kind: :data
        }
      end +
                   db_list_schema.map do |d|
                     {
                       version: d.to_i, kind: :schema
                     }
                   end

      sort == "asc" ? sort_migrations(migrations) : sort_migrations(migrations).reverse
    end
  end
end
