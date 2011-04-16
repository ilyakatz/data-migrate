require 'data_migrator'

namespace :db do


  namespace :migrate do
    namespace :status do
      desc "Display status of data and schema migrations"
      task :with_data => :environment do
        config = ActiveRecord::Base.configurations[Rails.env || 'development']
        ActiveRecord::Base.establish_connection(config)
        unless ActiveRecord::Base.connection.table_exists?(DataMigration::DataMigrator.schema_migrations_table_name)
          puts 'Data migrations table does not exist yet.'
          next  # means "return" for rake task
        end
        unless ActiveRecord::Base.connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name)
          puts 'Schema migrations table does not exist yet.'
          next  # means "return" for rake task
        end

        db_list_data = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigration::DataMigrator.schema_migrations_table_name}")
        db_list_schema = ActiveRecord::Base.connection.select_values("SELECT version FROM #{ActiveRecord::Migrator.schema_migrations_table_name}")
        file_list = []

        Dir.foreach(File.join(Rails.root, 'db', 'data')) do |file|
          # only files matching "20091231235959_some_name.rb" pattern
          if match_data = /(\d{14})_(.+)\.rb/.match(file)
            status = db_list_data.delete(match_data[1]) ? 'up' : 'down'
            file_list << [status, match_data[1], match_data[2], 'data']
          end
        end

        Dir.foreach(File.join(Rails.root, 'db', 'migrate')) do |file|
          # only files matching "20091231235959_some_name.rb" pattern
          if match_data = /(\d{14})_(.+)\.rb/.match(file)
            status = db_list_schema.delete(match_data[1]) ? 'up' : 'down'
            file_list << [status, match_data[1], match_data[2], 'schema']
          end
        end

        file_list.sort!{|a,b| "#{a[1]}_#{a[4] == 'data' ? 1 : 0}" <=> "#{b[1]}_#{b[4] == 'data' ? 1 : 0}" }

        # output
        puts "\ndatabase: #{config['database']}\n\n"
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
    end
  end # END OF MIGRATE NAME SPACE

  namespace :forward do
    desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
    task :with_data => :environment do
      # TODO: No worky for .forward
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      # DataMigration::DataMigrator.forward('db/data/', step)
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
        if pending_migration.is_data?
          DataMigration::DataMigrator.run(:up, "db/data/", pending_migration.version)
        elsif pending_migration.is_schema?
          ActiveRecord::Migrator.run(:up, "db/migrate/", pending_migration.version)
        end
      end
    end
  end

  namespace :version do
    desc "Retrieves the current schema version number"
    task :with_data => :environment do
      puts "Current version: #{[DataMigration::DataMigrator.current_version, ActiveRecord::Migrator.current_version].max}"
    end
  end

  namespace :abort_if_pending_migrations do
    desc "Raises an error if there are pending migrations"
    task :with_data => :environment do
      if defined? ActiveRecord
        if pending_data_migrations.any? || pending_schema_migrations.any?
          puts "You have #{pending_schema_migrations.size} pending schema migrations:"
          pending_schema_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          puts "You have #{pending_data_migrations.size} pending data migrations:"
          pending_data_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          abort %{Run "rake data:migrate:with_data" to update your database then try again.}
        end
      end
    end
  end
end

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

    desc "Display status of data migrations"
    task :status => :environment do
      config = ActiveRecord::Base.configurations[Rails.env || 'development']
      ActiveRecord::Base.establish_connection(config)
      unless ActiveRecord::Base.connection.table_exists?(DataMigration::DataMigrator.schema_migrations_table_name)
        puts 'Data migrations table does not exist yet.'
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
    # TODO: No worky for .forward
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    # DataMigration::DataMigrator.forward('db/data/', step)
    migrations = pending_data_migrations.reverse.pop(step).reverse
    migrations.each do | pending_migration |
      DataMigration::DataMigrator.run(:up, "db/data/", pending_migration.version)
    end
  end

  desc "Retrieves the current schema version number"
  task :version => :environment do
    puts "Current data version: #{DataMigration::DataMigrator.current_version}"
  end

  desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    if defined? ActiveRecord
      if pending_data_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_data_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake data:migrate" to update your database then try again.}
      end
    end
  end
end

def pending_migrations
  sort_migrations pending_data_migrations, pending_schema_migrations
end

def pending_data_migrations
  DataMigration::DataMigrator.new(:up, 'db/data').pending_migrations
end

def pending_schema_migrations
  ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
end

def sort_migrations set_1, set_2=nil
  migrations = set_1 + (set_2 || [])
  migrations.sort{|a,b|  sort_string(a) <=> sort_string(b)}
end

def sort_string migration
  "#{migration.version}_#{migration.is_data? ? 1 : 0}"
end
