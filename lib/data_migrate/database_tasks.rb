# frozen_string_literal: true

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a data_schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    def self.data_schema_file
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
      "db/data/"
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
        pending_migrations.map {|m| { version: m.version, kind: :data }})
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
  end
end
