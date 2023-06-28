# frozen_string_literal: true

module DataMigrate
  module Tasks
    module DataMigrateTasks
      extend self

      def migrations_paths
        @migrations_paths ||= DataMigrate.config.data_migrations_path
      end

      def dump
        if dump_schema_after_migration?
          filename = DataMigrate::DatabaseTasks.schema_file
          ActiveRecord::Base.establish_connection(DataMigrate.config.db_configuration) if DataMigrate.config.db_configuration
          File.open(filename, "w:utf-8") do |file|
            DataMigrate::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
      end

      def migrate
        target_version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil

        DataMigrate::DataMigrator.create_data_schema_table
        DataMigrate::MigrationContext.new(migrations_paths).migrate(target_version)
      end

      def abort_if_pending_migrations(migrations, message)
        if migrations.any?
          puts "You have #{migrations.size} pending #{'migration'.pluralize(migrations.size)}:"
          migrations.each do |pending_migration|
            puts "  %4d %s" % [pending_migration[:version], pending_migration[:name]]
          end
          abort message
        end
      end

      def dump_schema_after_migration?
        if ActiveRecord.respond_to?(:dump_schema_after_migration)
          ActiveRecord.dump_schema_after_migration
        else
          ActiveRecord::Base.dump_schema_after_migration
        end
      end

      def status
        DataMigrate::StatusService.dump
      end

      def status_with_schema
        db_list_data = ActiveRecord::Base.connection.select_values(
          "SELECT version FROM #{DataMigrate::DataSchemaMigration.table_name}"
        )
        db_list_schema = ActiveRecord::SchemaMigration.all.pluck(:version)
        file_list = []

        Dir.foreach(File.join(Rails.root, migrations_paths)) do |file|
          # only files matching "20091231235959_some_name.rb" pattern
          if match_data = /(\d{14})_(.+)\.rb/.match(file)
            status = db_list_data.delete(match_data[1]) ? 'up' : 'down'
            file_list << [status, match_data[1], match_data[2], 'data']
          end
        end

        DataMigrate::SchemaMigration.migrations_paths.map do |path|
          Dir.children(path) if Dir.exist?(path)
        end.flatten.compact.each do |file|
          # only files matching "20091231235959_some_name.rb" pattern
          if match_data = /(\d{14})_(.+)\.rb/.match(file)
            status = db_list_schema.delete(match_data[1]) ? 'up' : 'down'
            file_list << [status, match_data[1], match_data[2], 'schema']
          end
        end

        file_list.sort!{|a,b| "#{a[1]}_#{a[3] == 'data' ? 1 : 0}" <=> "#{b[1]}_#{b[3] == 'data' ? 1 : 0}" }

        # output
        puts "\ndatabase: #{database_name}\n\n"
        puts "#{"Status".center(8)} #{"Type".center(8)}  #{"Migration ID".ljust(14)} Migration Name"
        puts "-" * 60
        file_list.each do |file|
          puts "#{file[0].center(8)} #{file[3].center(8)} #{file[1].ljust(14)}  #{file[2].humanize}"
        end
        db_list_schema.each do |version|
          puts "#{'up'.center(8)}  #{version.ljust(14)}  *** NO SCHEMA FILE ***"
        end
        db_list_data.each do |version|
          puts "#{'up'.center(8)}  #{version.ljust(14)}  *** NO DATA FILE ***"
        end
        puts
      end

      private

      def database_name
        if Gem::Dependency.new("railties", "~> 7.0").match?("railties", Gem.loaded_specs["railties"].version)
          ActiveRecord::Base.connection_db_config.database
        elsif Gem::Dependency.new("railties", "~> 6.0").match?("railties", Gem.loaded_specs["railties"].version)
          ActiveRecord::Base.connection_config[:database]
        end
      end
    end
  end
end
