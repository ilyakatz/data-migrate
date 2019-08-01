# frozen_string_literal: true

require "data_migrate/config"

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    # This overrides ActiveRecord::Tasks::DatabaseTasks
    def self.schema_file(_format = nil)
      File.join(db_dir, "data_schema.rb")
    end

    def self.forward(step = 1)
      DataMigrate::DataMigrator.assure_data_schema_table
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
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
