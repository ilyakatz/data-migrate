module DataMigrate
  module Tasks
    module DataMigrateTasks
      extend self
      def migrations_paths
        @migrations_paths ||= DataMigrate.config.data_migrations_path
      end

      def migrate
        DataMigrate::DataMigrator.assure_data_schema_table
        target_version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        if Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 2
          DataMigrate::MigrationContext.new(migrations_paths).migrate(target_version)
        else
          DataMigrate::DataMigrator.migrate(migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
        end
      end
    end
  end
end
