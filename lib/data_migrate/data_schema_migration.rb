module DataMigrate
  class DataSchemaMigration < ActiveRecord::SchemaMigration
    class << self
      def table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def primary_key
        "version"
      end
    end
  end
end
