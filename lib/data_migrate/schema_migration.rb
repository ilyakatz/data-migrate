module DataMigrate
  # Helper class to getting access to db schema
  # to allow data/schema combiation tasks
  class SchemaMigration
    def self.pending_schema_migrations
      all_migrations = DataMigrate::MigrationContext.new(migrations_paths).migrations
      sort_migrations(
        ActiveRecord::Migrator.new(:up, all_migrations, ActiveRecord::Base.connection.schema_migration).
        pending_migrations.
        map {|m| { version: m.version, kind: :schema }}
      )
    end

    def self.run(direction, migration_paths, version)
      ActiveRecord::MigrationContext.new(migration_paths, ActiveRecord::Base.connection.schema_migration).run(direction, version)
    end

    def self.sort_migrations(set1, set2 = nil)
      migrations = set1 + (set2 || [])
      migrations.sort {|a, b|  sort_string(a) <=> sort_string(b)}
    end

    def self.migrations_paths
      spec_name = DataMigrate.config.spec_name
      if spec_name && Rails.version > '6.1'
        ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: spec_name).migrations_paths
      elsif spec_name
        ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, spec_name: spec_name).migrations_paths
      else
        Rails.application.config.paths["db/migrate"].to_a
      end
    end

    def self.sort_string(migration)
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end
  end
end
