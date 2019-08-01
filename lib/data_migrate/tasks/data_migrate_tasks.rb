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
        if (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 2) ||
          Rails::VERSION::MAJOR == 6
          DataMigrate::MigrationContext.new(migrations_paths).migrate(target_version)
        else
          DataMigrate::DataMigrator.migrate(migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
        end
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
