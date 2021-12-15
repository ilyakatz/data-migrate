module DataMigrate
  # Helper class to getting access to db schema
  # to allow data/schema combiation tasks
  class SchemaMigration
    def self.pending_schema_migrations
      all_migrations = DataMigrate::DataMigrator.migrations(migrations_paths)
      sort_migrations(
        ActiveRecord::Migrator.new(:up, all_migrations).
        pending_migrations.
        map {|m| { version: m.version, name: m.name, kind: :schema }}
      )
    end

    def self.run(direction, version)
      DataMigrate::DataMigrator.migration_context.run(direction, version)
    end

    def self.sort_migrations(set1, set2 = nil)
      migrations = set1 + (set2 || [])
      migrations.sort {|a, b|  sort_string(a) <=> sort_string(b)}
    end

    def self.migrations_paths
      # Rails.application.config.paths["db/migrate"].to_a
      DataMigrate.config.migrations_path
    end

    def self.sort_string(migration)
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end
  end
end
