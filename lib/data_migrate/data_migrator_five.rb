# frozen_string_literal: true

require "active_record"

module DataMigrate
  class DataMigrator < ActiveRecord::Migrator
    self.migrations_paths = ["db/data"]

    def self.assure_data_schema_table
      DataMigrate::DataSchemaMigration.create_table
    end

    def initialize(direction, migrations, target_version = nil)
      @direction         = direction
      @target_version    = target_version
      @migrated_versions = nil
      @migrations        = migrations

      validate(@migrations)

      DataMigrate::DataSchemaMigration.create_table
      ActiveRecord::InternalMetadata.create_table
    end

    def load_migrated
      # Certain versions of the gem wrote data migration versions into
      # schema_migrations table. After the fix, it was corrected to write into
      # data_migrations. However, not to break anything we are going to
      # get versions from both tables.
      #
      # This may cause some problems:
      # Eg. rake data:versions will show version from the schema_migrations table
      # which may be a version of actual schema migration and not data migration
      @migrated_versions =
        DataMigrate::DataSchemaMigration.normalized_versions.map(&:to_i).sort +
        ActiveRecord::SchemaMigration.normalized_versions.map(&:to_i).sort
    end

    class << self
      def current_version
        DataMigrate::MigrationContext.new(migrations_paths).current_version
      end

      ##
      # Compares the given filename with what we expect data migration
      # filenames to be, eg the "20091231235959_some_name.rb" pattern
      # @param (String) filename
      # @return (MatchData)
      def match(filename)
        /(\d{14})_(.+)\.rb/.match(filename)
      end

      def migrations_status
        DataMigrate::MigrationContext.new(migrations_paths).migrations_status
      end
    end

    private

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        DataMigrate::DataSchemaMigration.where(version: version.to_s).delete_all
      else
        migrated << version
        DataMigrate::DataSchemaMigration.create!(version: version.to_s)
      end
    end
  end
end
