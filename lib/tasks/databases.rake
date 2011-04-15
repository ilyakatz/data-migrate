require 'data_migrator'

namespace :data do
  task :load_config => :rails_env do
    require 'active_record'
    ActiveRecord::Base.configurations = Rails.application.config.database_configuration
  end

  task :migrate => :environment do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    DataMigration::DataMigrator.migrate("db/data/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end

  namespace :migrate do
    desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo => :environment do
      if ENV["VERSION"]
        Rake::Task["data:migrate:down"].invoke
        Rake::Task["data:migrate:up"].invoke
      else
        Rake::Task["data:rollback"].invoke
        Rake::Task["data:migrate"].invoke
      end
    end

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      DataMigration::DataMigrator.run(:up, "db/data/", version)
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      DataMigration::DataMigrator.run(:down, "db/data/", version)
    end

    desc "Display status of migrations"
    task :status => :environment do
      config = ActiveRecord::Base.configurations[Rails.env || 'development']
      ActiveRecord::Base.establish_connection(config)
      unless ActiveRecord::Base.connection.table_exists?(DataMigration::DataMigrator.schema_migrations_table_name)
        puts 'Schema migrations table does not exist yet.'
        next  # means "return" for rake task
      end
      db_list = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigration::DataMigrator.schema_migrations_table_name}")
      file_list = []
      Dir.foreach(File.join(Rails.root, 'db', 'data')) do |file|
        # only files matching "20091231235959_some_name.rb" pattern
        if match_data = /(\d{14})_(.+)\.rb/.match(file)
          status = db_list.delete(match_data[1]) ? 'up' : 'down'
          file_list << [status, match_data[1], match_data[2]]
        end
      end
      # output
      puts "\ndatabase: #{config['database']}\n\n"
      puts "#{"Status".center(8)}  #{"Migration ID".ljust(14)}  Migration Name"
      puts "-" * 50
      file_list.each do |file|
        puts "#{file[0].center(8)}  #{file[1].ljust(14)}  #{file[2].humanize}"
      end
      db_list.each do |version|
        puts "#{'up'.center(8)}  #{version.ljust(14)}  *** NO FILE ***"
      end
      puts
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    DataMigration::DataMigrator.rollback('db/data/', step)
  end

  desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward => :environment do
    # TODO: No worky
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    DataMigration::DataMigrator.forward('db/data/', step)
  end

  desc "Retrieves the current schema version number"
  task :version => :environment do
    puts "Current version: #{DataMigration::DataMigrator.current_version}"
  end

  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    if defined? ActiveRecord
      pending_migrations = DataMigration::DataMigrator.new(:up, 'db/data').pending_migrations

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake data:migrate" to update your database then try again.}
      end
    end
  end
end
