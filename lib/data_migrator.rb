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
    end
  end
end
