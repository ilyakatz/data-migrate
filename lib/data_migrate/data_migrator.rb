# frozen_string_literal: true

require "active_record"

module DataMigrate

  class DataMigrator < ActiveRecord::Migrator

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        DataMigrate::DataSchemaMigration.where(:version => version.to_s).delete_all
      else
        migrated << version
        DataMigrate::DataSchemaMigration.create!(:version => version.to_s)
      end
    end

    def load_migrated(connection = ActiveRecord::Base.connection)
      self.class.get_all_versions(connection)
    end

    class << self
      def current_version(connection = ActiveRecord::Base.connection)
        get_all_versions(connection).max || 0
      end

      def get_all_versions(connection = ActiveRecord::Base.connection)
        if table_exists?(connection, schema_migrations_table_name)
          DataMigrate::DataSchemaMigration.all.map { |x| x.version.to_i }.sort
        else
          []
        end
      end

      def schema_migrations_table_name
        ActiveRecord::Base.table_name_prefix + "data_migrations" +
          ActiveRecord::Base.table_name_suffix
      end

      ##
      # Provides the full migrations_path filepath
      # @return (String)
      def full_migrations_path
        DataMigrate.data_migrations_paths.first
      end

      def assure_data_schema_table
        ActiveRecord::Base.establish_connection(db_config)
        sm_table = DataMigrate::DataMigrator.schema_migrations_table_name

        unless table_exists?(ActiveRecord::Base.connection, sm_table)
          create_table(sm_table)
        end
      end

      ##
      # Compares the given filename with what we expect data migration
      # filenames to be, eg the "20091231235959_some_name.rb" pattern
      # @param (String) filename
      # @return (MatchData)
      def match(filename)
        /(\d{14})_(.+)\.rb/.match(filename)
      end

      private

      def create_table(sm_table)
        ActiveRecord::Base.connection.create_table(sm_table, :id => false) do |schema_migrations_table|
            schema_migrations_table.column :version, :string, :null => false
          end

          suffix = ActiveRecord::Base.table_name_suffix
          prefix = ActiveRecord::Base.table_name_prefix
          index_name = "#{prefix}unique_data_migrations#{suffix}"

          ActiveRecord::Base.connection.add_index sm_table, :version,
            :unique => true,
            :name => index_name
      end

      def table_exists?(connection, table_name)
        # Avoid the warning that table_exists? prints in Rails 5.0 due a
        # change in behavior between Rails 5.0 and Rails 5.1 of this method
        # with respect to database views.
        if ActiveRecord.version >= Gem::Version.new("5.0") &&
           ActiveRecord.version < Gem::Version.new("5.1")
          connection.data_source_exists?(table_name)
        else
          connection.table_exists?(schema_migrations_table_name)
        end
      end

      def db_config
        ActiveRecord::Base.configurations[Rails.env || "development"] ||
          ENV["DATABASE_URL"]
      end
    end
  end
end
