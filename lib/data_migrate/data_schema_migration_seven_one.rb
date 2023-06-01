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

class ActiveRecord::SchemaMigration

  def self.create_table
    ActiveRecord::Base.connection.schema_migration.create_table
  end

  def self.schema_migrations_table_name
    ActiveRecord::Base.connection.schema_migration.table_name
  end

  def self.table_exists?
    ActiveRecord::Base.connection.schema_migration.table_exists?
  end

  def self.create(version:)
    ActiveRecord::Base.connection.schema_migration.create_version(version)
  end

  def self.normalize_migration_number(version)
    ActiveRecord::Base.connection.schema_migration.normalize_migration_number(version)
  end

  def self.normalized_versions
    ActiveRecord::Base.connection.schema_migration.normalized_versions
  end
end
