module DataMigrate
  module Tasks
    module DataMigrateTasks
      extend self
      def migrations_paths
        @migrations_paths ||= DataMigrate.config.data_migrations_path
      end

      def dump
        if ActiveRecord::Base.dump_schema_after_migration
          filename = DataMigrate::DatabaseTasks.schema_file
          ActiveRecord::Base.establish_connection(DataMigrate.config.db_configuration) if DataMigrate.config.db_configuration
          File.open(filename, "w:utf-8") do |file|
            DataMigrate::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
      end

      def migrate
        DataMigrate::DataMigrator.assure_data_schema_table
        target_version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        DataMigrate::MigrationContext.new(migrations_paths).migrate(target_version)
      end

      def abort_if_pending_migrations(migrations, message)
        if migrations.any?
          puts "You have #{migrations.size} pending #{migrations.size > 1 ? 'migrations:' : 'migration:'}"
          migrations.each do |pending_migration|
            puts "  %4d %s" % [pending_migration[:version], pending_migration[:name]]
          end
          abort message
        end
      end
    end
  end
end
