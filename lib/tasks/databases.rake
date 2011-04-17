require 'data_migrator'

namespace :db do
  namespace :migrate do
    namespace :down do
      desc 'Runs the "down" for a given migration VERSION.'
      task :with_data => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        config = connect_to_database
        migrations = past_migrations.keep_if{|m| m[:version] == version}

        if migrations.size > 1
          raise "Ambiguous migration name. Use 'db:migrate:down' or 'data:migrate:down' instead"
        elsif migrations.size == 1
          if migrations.first[:kind] == :data
            ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
            DataMigration::DataMigrator.run(:down, "db/data/", version)
          else
            ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
            ActiveRecord::Migrator.run(:down, "db/migrate/", version)
          end
        end
      end
    end

    namespace :status do
      desc "Display status of data and schema migrations"
      task :with_data => :environment do
        config = connect_to_database
        next unless config

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

        file_list.sort!{|a,b| "#{a[1]}_#{a[3] == 'data' ? 1 : 0}" <=> "#{b[1]}_#{b[3] == 'data' ? 1 : 0}" }

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

  namespace :rollback do
    desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task :with_data => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      config = connect_to_database
      next unless config
      past_migrations('desc')[0..(step - 1)].each do | past_migration |
        if past_migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          DataMigration::DataMigrator.run(:down, "db/data/", past_migration[:version])
        elsif past_migration[:kind] == :schema
          ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
          ActiveRecord::Migrator.run(:down, "db/migrate/", past_migration[:version])
        end
      end
    end
  end

  namespace :forward do
    desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
    task :with_data => :environment do
      # TODO: No worky for .forward
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      # DataMigration::DataMigrator.forward('db/data/', step)
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
        if pending_migration.is_data?
          ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          DataMigration::DataMigrator.run(:up, "db/data/", pending_migration.version)
        elsif pending_migration.is_schema?
          ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
          ActiveRecord::Migrator.run(:up, "db/migrate/", pending_migration.version)
        end
      end
    end
  end

  namespace :version do
    desc "Retrieves the current schema version numbers for data and schema migrations"
    task :with_data => :environment do
      puts "Current Schema version: #{ActiveRecord::Migrator.current_version}"
      puts "Current Data version: #{DataMigration::DataMigrator.current_version}"
    end
  end
end

namespace :data do
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

  desc "Retrieves the current schema version number for data migrations"
  task :version => :environment do
    puts "Current data version: #{DataMigration::DataMigrator.current_version}"
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

def connect_to_database
  config = ActiveRecord::Base.configurations[Rails.env || 'development']
  ActiveRecord::Base.establish_connection(config)

  unless ActiveRecord::Base.connection.table_exists?(DataMigration::DataMigrator.schema_migrations_table_name)
    puts 'Data migrations table does not exist yet.'
    config = nil
  end
  unless ActiveRecord::Base.connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name)
    puts 'Schema migrations table does not exist yet.'
    config = nil
  end
  config
end

def past_migrations sort=nil
  sort = sort.downcase if sort
  db_list_data = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigration::DataMigrator.schema_migrations_table_name}").sort
  db_list_schema = ActiveRecord::Base.connection.select_values("SELECT version FROM #{ActiveRecord::Migrator.schema_migrations_table_name}").sort
  migrations = db_list_data.map{|d| {:version => d.to_i, :kind => :data }} + db_list_schema.map{|d| {:version => d.to_i, :kind => :schema }}

  if sort == 'desc'
    migrations.sort!{|a, b| "#{b[:version]}_#{b[:kind] == :data ? 1 :0}" <=>  "#{a[:version]}_#{a[:kind] == :data ? 1 :0}" }
  else
    migrations.sort!{|a, b| "#{b[:version]}_#{a[:kind] == :data ? 1 :0}" <=>  "#{b[:version]}_#{b[:kind] == :data ? 1 :0}" }
  end
end
