module DataMigrate
  class DataSchemaMigration < ::ActiveRecord::SchemaMigration

    class << self
      def table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def index_name
        "#{table_name_prefix}unique_data_migrations#{table_name_suffix}"
      end
    end
  end
end

