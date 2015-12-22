require 'active_record'

module DataMigrate
  class DataMigrator < ActiveRecord::Migrator
    class << self
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
