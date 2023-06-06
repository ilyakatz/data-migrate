module DataMigrate
  # Helper class to getting access to db schema
  # to allow data/schema combination tasks
  class SchemaMigration
    def self.pending_schema_migrations
      all_migrations = DataMigrate::MigrationContext.new(migrations_paths).migrations
      sort_migrations(
        ActiveRecord::Migrator.new(:up, all_migrations, ActiveRecord::Base.connection.schema_migration, ActiveRecord::Base.connection.internal_metadata).
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
      if spec_name
        ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: spec_name).migrations_paths
      else
        Rails.application.config.paths["db/migrate"].to_a
      end
    end

    def self.sort_string(migration)
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end
  end
end

# ActiveRecord::SchemaMigration no longer inherits from ActiveRecord::Base in Rails 7.1
# and now has updated method names. See: https://github.com/rails/rails/pull/45908
# This patch delegates SchemaMigration calls to the updated connection instance.
class ActiveRecord::SchemaMigration
  class << self
    delegate :create_table, :table_exists?, :normalized_versions, to: :schema_migration

    def schema_migration
      ActiveRecord::Base.connection.schema_migration
    end
  end

  def self.schema_migrations_table_name
    ActiveRecord::Base.connection.schema_migration.table_name
  end

  def self.create(version:)
    ActiveRecord::Base.connection.schema_migration.create_version(version)
  end

  def self.normalize_migration_number(version)
    ActiveRecord::Base.connection.schema_migration.normalize_migration_number(version)
  end
end
