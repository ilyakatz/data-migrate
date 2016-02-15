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
          # get versions from both tables
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
    end
  end
end
