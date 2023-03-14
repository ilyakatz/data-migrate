module DataMigrate
  class DataSchemaMigration
    class << self
      delegate :table_name, :primary_key, :create_table, :normalized_versions, :create, :create!, :table_exists?, :exists?, :where, to: :instance

      def instance
        @instance ||= begin 
          instance = ActiveRecord::Base.connection.schema_migration
          instance.instance_exec do 
            define_singleton_method(:table_name) { ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix }
            define_singleton_method(:primary_key) { "version" }
          end

          instance
        end
      end
    end
  end
end
