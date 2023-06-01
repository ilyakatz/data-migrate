module DataMigrate
  class DataSchemaMigration
    class << self
      delegate :table_name, :primary_key, :create_table, :normalized_versions, :create_version, :create!, :table_exists?, :exists?, :where, to: :instance

      def instance
        @instance ||= Class.new(::ActiveRecord::SchemaMigration) do
          define_method(:table_name) { ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix }
          define_method(:primary_key) { "version" }
        end.new(ActiveRecord::Base.connection)
      end

      def delete_version(version:)
        instance.delete_version(version)
      end

      def create(version:)
        instance.create_version(version)
      end

      def create!(version:)
        instance.create_version(version)
      end
    end
  end
end

# ActiveRecord::SchemaMigration no longer inherits from ActiveRecord::Base
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
