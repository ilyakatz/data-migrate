module DataMigrate
  class RailsHelper
    class << self
      def rails_version_equal_to_or_higher_than_7_1
        return @equal_to_or_higher_than_7_1 if defined?(@equal_to_or_higher_than_7_1)

        @equal_to_or_higher_than_7_1 = Gem::Dependency.new("railties", ">= 7.1.0.alpha").match?("railties", Gem.loaded_specs["railties"].version, true)
      end

      def rails_version_equal_to_or_higher_than_7_0
        return @rails_version_equal_to_or_higher_than_7_0 if defined?(@rails_version_equal_to_or_higher_than_7_0)

        @rails_version_equal_to_or_higher_than_7_0 = Gem::Dependency.new("railties", ">= 7.0").match?("railties", Gem.loaded_specs["railties"].version, true)
      end

      def internal_metadata
        if rails_version_equal_to_or_higher_than_7_1
          ActiveRecord::Base.connection.internal_metadata
        else
          ActiveRecord::InternalMetadata
        end
      end

      def schema_migration
        if rails_version_equal_to_or_higher_than_7_1
          ActiveRecord::Base.connection.schema_migration
        else
          ActiveRecord::SchemaMigration
        end
      end

      def schema_migration_versions
        if rails_version_equal_to_or_higher_than_7_1
          schema_migration.versions
        else
          schema_migration.all.pluck(:version)
        end
      end

      def schema_create_version(version)
        if rails_version_equal_to_or_higher_than_7_1
          schema_migration.create_version(version)
        else
          schema_migration.create(version: version)
        end
      end

      def data_schema_delete_version(version)
        if rails_version_equal_to_or_higher_than_7_1
          data_schema_migration.delete_version(version)
        else
          data_schema_migration.where(version: version.to_s).delete_all
        end
      end

      def data_schema_migration
        if rails_version_equal_to_or_higher_than_7_1
          DataMigrate::DataSchemaMigration.new(ActiveRecord::Tasks::DatabaseTasks.migration_connection)
        else
          DataMigrate::DataSchemaMigration
        end
      end

      def data_migrator(
        direction,
        migrations,
        schema_migration = DataMigrate::RailsHelper.schema_migration,
        internal_metadata = DataMigrate::RailsHelper.internal_metadata,
        target_version = nil
      )
        if rails_version_equal_to_or_higher_than_7_1
          DataMigrate::DataMigrator.new(direction, migrations, schema_migration, internal_metadata, target_version)
        else
          DataMigrate::DataMigrator.new(direction, migrations, schema_migration, target_version)
        end
      end
    end
  end
end
