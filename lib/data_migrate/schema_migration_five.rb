module DataMigrate
  # Helper class to getting access to db schema
  # to allow data/schema combiation tasks
  class SchemaMigration
    def self.pending_schema_migrations
      all_migrations = ActiveRecord::MigrationContext.new(migrations_paths).migrations
      sort_migrations(
        ActiveRecord::Migrator.new(:up, all_migrations).
        pending_migrations.
        map {|m| { version: m.version, kind: :schema }}
      )
    end

    def self.run(direction, migration_paths, version)
      ActiveRecord::MigrationContext.new(migration_paths).run(direction, version)
    end

    def self.sort_migrations(set1, set2 = nil)
      migrations = set1 + (set2 || [])
      migrations.sort {|a, b|  sort_string(a) <=> sort_string(b)}
    end

    def self.migrations_paths
      DataMigrate.db_migrations_paths
    end

    def self.sort_string(migration)
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end
  end
end
