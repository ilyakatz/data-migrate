namespace :db do
  namespace :migrate do
    desc "Migrate the database data and schema (options: VERSION=x, VERBOSE=false)."
    task :with_data => :environment do
      assure_data_schema_table

      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      target_version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      migrations = []

      if target_version.nil?
        migrations = pending_migrations.map{ |m| m.merge(:direction =>:up) }
      else
        current_schema_version = ActiveRecord::Migrator.current_version
        schema_migrations = if target_version > current_schema_version
                              pending_schema_migrations.keep_if{ |m| m[:version] <= target_version }.map{ |m| m.merge(:direction =>:up) }
                            elsif target_version < current_schema_version
                              past_migrations.keep_if{ |m| m[:version] > target_version }.map{ |m| m.merge(:direction =>:down) }
                            else # ==
                              []
                            end

        current_data_version = ActiveRecord::Migrator.current_version
        data_migrations = if target_version > current_data_version
                            pending_data_migrations.keep_if{ |m| m[:version] <= target_version }.map{ |m| m.merge(:direction =>:up) }
                          elsif target_version < current_data_version
                            past_migrations.keep_if{ |m| m[:version] > target_version }.map{ |m| m.merge(:direction =>:down) }
                          else # ==
                            []
                          end
        migrations = if schema_migrations.empty?
                       data_migrations
                     elsif data_migrations.empty?
                       schema_migrations
                     elsif target_version > current_data_version && target_version > current_schema_version
                       sort_migrations data_migrations, schema_migrations
                     elsif target_version < current_data_version && target_version < current_schema_version
                       sort_migrations(data_migrations, schema_migrations).reverse
                     elsif target_version > current_data_version && target_version < current_schema_version
                       schema_migrations + data_migrations
                     elsif target_version < current_data_version && target_version > current_schema_version
                       schema_migrations + data_migrations
                     end
      end

      migrations.each do |migration|
        if migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          DataMigrate::DataMigrator.run(migration[:direction], DataMigrate::DataMigrator.migrations_path, migration[:version])
        else
          ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
          ActiveRecord::Migrator.run(migration[:direction], "db/migrate/", migration[:version])
        end
      end

      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    namespace :redo do
      desc 'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
      task :with_data => :environment do
      assure_data_schema_table
        if ENV["VERSION"]
          Rake::Task["db:migrate:down:with_data"].invoke
          Rake::Task["db:migrate:up:with_data"].invoke
        else
          Rake::Task["db:rollback:with_data"].invoke
          Rake::Task["db:migrate:with_data"].invoke
        end
      end
    end

    namespace :up do
      desc 'Runs the "up" for a given migration VERSION. (options both=false)'
      task :with_data => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        assure_data_schema_table
        run_both = ENV["BOTH"] == "true"
        migrations = pending_migrations.keep_if{|m| m[:version] == version}

        unless run_both || migrations.size < 2
          migrations = migrations.slice(0,1)
        end

        migrations.each do |migration|
          if migration[:kind] == :data
            ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
            DataMigrate::DataMigrator.run(:up, DataMigrate::DataMigrator.migrations_path, migration[:version])
          else
            ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
            ActiveRecord::Migrator.run(:up, "db/migrate/", migration[:version])
          end
        end
      end
    end

    namespace :down do
      desc 'Runs the "down" for a given migration VERSION. (option BOTH=false)'
      task :with_data => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        assure_data_schema_table
        run_both = ENV["BOTH"] == "true"
        migrations = past_migrations.keep_if{|m| m[:version] == version}

        unless run_both || migrations.size < 2
          migrations = migrations.slice(0,1)
        end

        migrations.each do |migration|
          if migration[:kind] == :data
            ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
            DataMigrate::DataMigrator.run(:down, DataMigrate::DataMigrator.migrations_path, migration[:version])
          else
            ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
            ActiveRecord::Migrator.run(:down, "db/migrate/", migration[:version])
          end
        end
      end
    end

    namespace :status do
      desc "Display status of data and schema migrations"
      task :with_data => :environment do
        config = connect_to_database
        next unless config

        db_list_data = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}")
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
      assure_data_schema_table
      past_migrations[0..(step - 1)].each do | past_migration |
        if past_migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          DataMigrate::DataMigrator.run(:down, DataMigrate::DataMigrator.migrations_path, past_migration[:version])
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
      assure_data_schema_table
      # TODO: No worky for .forward
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      # DataMigrate::DataMigrator.forward('db/data/', step)
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
        if pending_migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
          DataMigrate::DataMigrator.run(:up, DataMigrate::DataMigrator.migrations_path, pending_migration[:version])
        elsif pending_migration[:kind] == :schema
          ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
          ActiveRecord::Migrator.run(:up, "db/migrate/", pending_migration[:version])
        end
      end
    end
  end

  namespace :version do
    desc "Retrieves the current schema version numbers for data and schema migrations"
    task :with_data => :environment do
      assure_data_schema_table
      puts "Current Schema version: #{ActiveRecord::Migrator.current_version}"
      puts "Current Data version: #{DataMigrate::DataMigrator.current_version}"
    end
  end
end

namespace :data do
  desc 'Migrate data migrations (options: VERSION=x, VERBOSE=false)'
  task :migrate => :environment do
    ENV['REQUIRED_DATA_MIGRATIONS'] = nil
    assure_data_schema_table
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    DataMigrate::DataMigrator.migrate(DataMigrate::DataMigrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end

  namespace :migrate do

    desc 'Migrate required data migrations.'
    task :required => :environment do
      ENV['REQUIRED_DATA_MIGRATIONS'] = 'true'
      assure_data_schema_table
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      DataMigrate::DataMigrator.migrate(DataMigrate::DataMigrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end

    desc 'Migrate both required and non-required data migrations.'
    task :all => :environment do

      ENV['REQUIRED_DATA_MIGRATIONS'] = 'true'
      assure_data_schema_table
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      DataMigrate::DataMigrator.migrate(DataMigrate::DataMigrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)

      ENV['REQUIRED_DATA_MIGRATIONS'] = nil
      assure_data_schema_table
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      DataMigrate::DataMigrator.migrate(DataMigrate::DataMigrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end

    desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo => :environment do
      assure_data_schema_table
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
      assure_data_schema_table
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      DataMigrate::DataMigrator.run(:up, DataMigrate::DataMigrator.migrations_path, version)
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      assure_data_schema_table
      DataMigrate::DataMigrator.run(:down, DataMigrate::DataMigrator.migrations_path, version)
    end

    desc "Display status of data migrations"
    task :status => :environment do
      config = ActiveRecord::Base.configurations[Rails.env || 'development']
      ActiveRecord::Base.establish_connection(config)
      unless ActiveRecord::Base.connection.table_exists?(DataMigrate::DataMigrator.schema_migrations_table_name)
        puts 'Data migrations table does not exist yet.'
        next  # means "return" for rake task
      end
      db_list = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}")
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
    assure_data_schema_table
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    DataMigrate::DataMigrator.rollback(DataMigrate::DataMigrator.migrations_path, step)
  end

  desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward => :environment do
    assure_data_schema_table
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    # TODO: No worky for .forward
    # DataMigrate::DataMigrator.forward('db/data/', step)
    migrations = pending_data_migrations.reverse.pop(step).reverse
    migrations.each do | pending_migration |
      DataMigrate::DataMigrator.run(:up, DataMigrate::DataMigrator.migrations_path, pending_migration[:version])
    end
  end

  desc "Retrieves the current schema version number for data migrations"
  task :version => :environment do
    assure_data_schema_table
    puts "Current data version: #{DataMigrate::DataMigrator.current_version}"
  end
end

def pending_migrations
  sort_migrations pending_data_migrations, pending_schema_migrations
end

def pending_data_migrations
  sort_migrations DataMigrate::DataMigrator.new(:up, DataMigrate::DataMigrator.migrations_path).pending_migrations.map{|m| { :version => m.version, :kind => :data }}
end

def pending_schema_migrations
  sort_migrations ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.map{|m| { :version => m.version, :kind => :schema }}
end

def sort_migrations set_1, set_2=nil
  migrations = set_1 + (set_2 || [])
  migrations.sort{|a,b|  sort_string(a) <=> sort_string(b)}
end

def sort_string migration
  "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
end

def connect_to_database
  config = ActiveRecord::Base.configurations[Rails.env || 'development']
  ActiveRecord::Base.establish_connection(config)

  unless ActiveRecord::Base.connection.table_exists?(DataMigrate::DataMigrator.schema_migrations_table_name)
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
  db_list_data = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}").sort
  db_list_schema = ActiveRecord::Base.connection.select_values("SELECT version FROM #{ActiveRecord::Migrator.schema_migrations_table_name}").sort
  migrations = db_list_data.map{|d| {:version => d.to_i, :kind => :data }} + db_list_schema.map{|d| {:version => d.to_i, :kind => :schema }}

  sort == 'asc' ? sort_migrations(migrations) : sort_migrations(migrations).reverse
end

def assure_data_schema_table
  config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV["DATABASE_URL"]
  ActiveRecord::Base.establish_connection(config)
  sm_table = DataMigrate::DataMigrator.schema_migrations_table_name

  unless ActiveRecord::Base.connection.table_exists?(sm_table)
    ActiveRecord::Base.connection.create_table(sm_table, :id => false) do |schema_migrations_table|
      schema_migrations_table.column :version, :string, :null => false
    end
    ActiveRecord::Base.connection.add_index sm_table, :version, :unique => true, :name => "#{ActiveRecord::Base.table_name_prefix}unique_data_migrations#{ActiveRecord::Base.table_name_suffix}"
  end
end
