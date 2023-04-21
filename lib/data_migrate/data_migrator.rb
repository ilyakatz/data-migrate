# frozen_string_literal: true

require "active_record"
require "data_migrate/config"

module DataMigrate
  class DataMigrator < ActiveRecord::Migrator
    def self.migrations_paths
      [DataMigrate.config.data_migrations_path]
    end

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
      @migrated_versions =
        DataMigrate::DataSchemaMigration.normalized_versions.map(&:to_i).sort
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
        /(\d{14})_(.+)\.rb$/.match(filename)
      end

      def needs_migration?
        DataMigrate::DatabaseTasks.pending_migrations.count.positive?
      end
      ##
      # Provides the full migrations_path filepath
      # @return (String)
      def full_migrations_path
        File.join(Rails.root, *migrations_paths.split(File::SEPARATOR))
      end

      def migrations_status
        DataMigrate::MigrationContext.new(migrations_paths).migrations_status
      end

      # TODO: this was added to be backward compatible, need to re-evaluate
      def migrations(_migrations_paths)
        #DataMigrate::MigrationContext.new(migrations_paths).migrations
        DataMigrate::MigrationContext.new(_migrations_paths).migrations
      end

      #TODO: this was added to be backward compatible, need to re-evaluate
      def run(direction, migration_paths, version)
        DataMigrate::MigrationContext.new(migration_paths).run(direction, version)
      end

      def rollback(migrations_path, steps)
        DataMigrate::MigrationContext.new(migrations_path).rollback(steps)
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
