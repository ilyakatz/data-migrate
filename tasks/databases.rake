# frozen_string_literal: true

require 'data_migrate/tasks/data_migrate_tasks'
require 'data_migrate/tasks/setup_tests'

namespace :db do
  namespace :migrate do
    desc "Migrate the database data and schema (options: VERSION=x, VERBOSE=false)."
    task :with_data => :load_config do
      DataMigrate::DatabaseTasks.migrate_with_data
      Rake::Task["db:_dump"].invoke
      Rake::Task["data:dump"].invoke
    end

    namespace :redo do
      desc 'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
      task :with_data => :environment do
        DataMigrate::DataMigrator.create_data_schema_table
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
        DataMigrate::DataMigrator.create_data_schema_table
        run_both = ENV["BOTH"] == "true"
        migrations = DataMigrate::DatabaseTasks.pending_migrations.keep_if{|m| m[:version] == version}

        unless run_both || migrations.size < 2
          migrations = migrations.slice(0,1)
        end

        migrations.each do |migration|
          DataMigrate::DatabaseTasks.run_migration(migration, :up)
        end

        Rake::Task["db:_dump"].invoke
        Rake::Task["data:dump"].invoke
      end
    end

    namespace :down do
      desc 'Runs the "down" for a given migration VERSION. (option BOTH=false)'
      task :with_data => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        DataMigrate::DataMigrator.create_data_schema_table
        run_both = ENV["BOTH"] == "true"
        migrations = DataMigrate::DatabaseTasks.past_migrations.keep_if{|m| m[:version] == version}

        unless run_both || migrations.size < 2
          migrations = migrations.slice(0,1)
        end

        migrations.each do |migration|
          DataMigrate::DatabaseTasks.run_migration(migration, :down)
        end

        Rake::Task["db:_dump"].invoke
        Rake::Task["data:dump"].invoke
      end
    end

    namespace :status do
      desc "Display status of data and schema migrations"
      task :with_data => :environment do
        DataMigrate::Tasks::DataMigrateTasks.status_with_schema
      end
    end
  end # END OF MIGRATE NAME SPACE

  namespace :rollback do
    desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task :with_data => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      DataMigrate::DataMigrator.create_data_schema_table
      DataMigrate::DatabaseTasks.past_migrations[0..(step - 1)].each do | past_migration |
        DataMigrate::DatabaseTasks.run_migration(past_migration, :down)
      end

      Rake::Task["db:_dump"].invoke
      Rake::Task["data:dump"].invoke
    end
  end

  namespace :forward do
    desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
    task :with_data => :environment do
      DataMigrate::DataMigrator.create_data_schema_table
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      DataMigrate::DatabaseTasks.forward(step)
      Rake::Task["db:_dump"].invoke
      Rake::Task["data:dump"].invoke
    end
  end

  namespace :version do
    desc "Retrieves the current schema version numbers for data and schema migrations"
    task :with_data => :environment do
      DataMigrate::DataMigrator.create_data_schema_table
      puts "Current Schema version: #{ActiveRecord::Migrator.current_version}"
      puts "Current Data version: #{DataMigrate::DataMigrator.current_version}"
    end
  end

  namespace :abort_if_pending_migrations do
    desc "Raises an error if there are pending migrations or data migrations"
    task with_data: :environment do
      message = %{Run `rake db:migrate:with_data` to update your database then try again.}
      DataMigrate::Tasks::DataMigrateTasks.abort_if_pending_migrations(DataMigrate::DatabaseTasks.pending_migrations, message)
    end
  end

  namespace :schema do
    namespace :load do
      desc "Load both schema.rb and data_schema.rb file into the database"
      task with_data: :environment do
        Rake::Task["db:schema:load"].invoke

        DataMigrate::DatabaseTasks.load_schema_current(
          :ruby,
          ENV["DATA_SCHEMA"]
        )
      end
    end
  end

  namespace :structure do
    namespace :load do
      desc "Load both structure.sql and data_schema.rb file into the database"
      task with_data: :environment do
        Rake::Task["db:structure:load"].invoke

        DataMigrate::DatabaseTasks.load_schema_current(
          :ruby,
          ENV["DATA_SCHEMA"]
        )
      end
    end
  end

  namespace :prepare do
    desc "Runs setup if database does not exist, or runs data and schema migrations if it does"
    task with_data: :environment do
      DataMigrate::DatabaseTasks.prepare_all_with_data
    end
  end
end

namespace :data do
  desc 'Migrate data migrations (options: VERSION=x, VERBOSE=false)'
  task :migrate => :environment do
    DataMigrate::Tasks::DataMigrateTasks.migrate
    Rake::Task["data:dump"].invoke
  end

  namespace :migrate do
    desc  'Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
    task :redo => :environment do
      DataMigrate::DataMigrator.create_data_schema_table
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
      DataMigrate::DataMigrator.create_data_schema_table
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      DataMigrate::DataMigrator.run(:up, DataMigrate::DatabaseTasks.data_migrations_path, version)
      Rake::Task["data:dump"].invoke
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      DataMigrate::DataMigrator.create_data_schema_table
      DataMigrate::DataMigrator.run(:down, DataMigrate::DatabaseTasks.data_migrations_path, version)
      Rake::Task["data:dump"].invoke
    end

    desc "Display status of data migrations"
    task :status => :environment do
      DataMigrate::Tasks::DataMigrateTasks.status
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :environment do
    DataMigrate::DataMigrator.create_data_schema_table
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    DataMigrate::DataMigrator.rollback(DataMigrate::DatabaseTasks.data_migrations_path, step)
    Rake::Task["data:dump"].invoke
  end

  desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward => :environment do
    DataMigrate::DataMigrator.create_data_schema_table
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    # TODO: No worky for .forward
    # DataMigrate::DataMigrator.forward('db/data/', step)
    migrations = DataMigrate::DatabaseTasks.pending_data_migrations.reverse.pop(step).reverse
    migrations.each do | pending_migration |
      DataMigrate::DataMigrator.run(:up, DataMigrate::DatabaseTasks.data_migrations_path, pending_migration[:version])
    end
    Rake::Task["data:dump"].invoke
  end

  desc "Retrieves the current schema version number for data migrations"
  task :version => :environment do
    DataMigrate::DataMigrator.create_data_schema_table
    puts "Current data version: #{DataMigrate::DataMigrator.current_version}"
  end

  desc "Raises an error if there are pending data migrations"
  task abort_if_pending_migrations: :environment do
    message = %{Run `rake data:migrate` to update your database then try again.}
    DataMigrate::Tasks::DataMigrateTasks.abort_if_pending_migrations(DataMigrate::DatabaseTasks.pending_data_migrations, message)
  end

  desc "Create a db/data_schema.rb file that stores the current data version"
  task dump: :environment do
    DataMigrate::Tasks::DataMigrateTasks.dump

    # Allow this task to be called as many times as required. An example
    # is the migrate:redo task, which calls other two internally
    # that depend on this one.
    Rake::Task["data:dump"].reenable
  end

  namespace :schema do
    desc "Load data_schema.rb file into the database"
    task load: :environment do
      DataMigrate::DatabaseTasks.load_schema_current(
        :ruby,
        ENV["DATA_SCHEMA"]
      )
    end
  end

  namespace :tests do
    desc "Setup hook for additional functionality"
    task setup: :environment do
      DataMigrate::Tasks::SetupTests.new.call
    end
  end
end
