require 'active_record'

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

    class << self
      def get_all_versions(connection = ActiveRecord::Base.connection)
        if connection.table_exists?(schema_migrations_table_name)
          # Certain versions of the gem wrote data migration versions into
          # schema_migrations table. After the fix, it was corrected to write into
          # data_migrations. However, not to break anything we are going to
          # get versions from both tables.
          #
          # This may cause some problems:
          # Eg. rake data:versions will show version from the schema_migrations table
          # which may be a version of actual schema migration and not data migration
          DataMigrate::DataSchemaMigration.all.map { |x| x.version.to_i }.sort +
            ActiveRecord::SchemaMigration.all.map { |x| x.version.to_i }.sort
        else
          []
        end
      end

      def schema_migrations_table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def migrations_path
        'db/data'
      end

      def assure_data_schema_table
        config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV["DATABASE_URL"]
        ActiveRecord::Base.establish_connection(config)
        sm_table = DataMigrate::DataMigrator.schema_migrations_table_name

        unless ActiveRecord::Base.connection.table_exists?(sm_table)
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
      end

    end
  end
end
