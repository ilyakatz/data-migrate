# frozen_string_literal: true

require "data_migrate/config"

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a schema_file method.
  module DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks
    extend self

    if respond_to?(:register_task)
      register_task(/mysql/,        "ActiveRecord::Tasks::MySQLDatabaseTasks")
      register_task(/trilogy/,      "ActiveRecord::Tasks::MySQLDatabaseTasks")
      register_task(/postgresql/,   "ActiveRecord::Tasks::PostgreSQLDatabaseTasks")
      register_task(/sqlite/,       "ActiveRecord::Tasks::SQLiteDatabaseTasks")
    end

    # These method are only introduced in Rails 7.1
    unless respond_to?(:with_temporary_pool_for_each)
      def with_temporary_pool_for_each(env: ActiveRecord::Tasks::DatabaseTasks.env, name: nil, &block) # :nodoc:
        if name
          db_config = ActiveRecord::Base.configurations.configs_for(env_name: env, name: name)
           with_temporary_pool(db_config, &block)
        else
          ActiveRecord::Base.configurations.configs_for(env_name: env, name: name).each do |db_config|
             with_temporary_pool(db_config, &block)
          end
        end
      end

      def with_temporary_connection(db_config, &block) # :nodoc:
        with_temporary_pool(db_config) do |pool|
          pool.with_connection(&block)
        end
      end

      def migration_class # :nodoc:
        ActiveRecord::Base
      end

      def migration_connection # :nodoc:
        migration_class.connection
      end

      private def with_temporary_pool(db_config)
        original_db_config = migration_class.connection_db_config
        pool = migration_class.connection_handler.establish_connection(db_config)

        yield pool
      ensure
        migration_class.connection_handler.establish_connection(original_db_config)
      end
    end

    def db_configs_with_versions
      db_configs_with_versions = Hash.new { |h, k| h[k] = [] }

      with_temporary_pool_for_each do |pool|
        db_config = pool.db_config
        if db_config.primary?
          versions_to_run = DataMigrate::DatabaseTasks.pending_data_migrations.map { |m| m[:version] }
          target_version = ActiveRecord::Tasks::DatabaseTasks.target_version

          versions_to_run.each do |version|
            next if target_version && target_version != version
            db_configs_with_versions[version] << DatabaseConfigurationWrapper.new(db_config)
          end
        end
      end

      db_configs_with_versions
    end

    def schema_file(_format = nil)
      File.join(db_dir, "data_schema.rb")
    end

    def schema_file_type(_format = nil)
      "data_schema.rb"
    end

    # This method is removed in Rails 7.0
    def dump_filename(spec_name, format = ActiveRecord::Base.schema_format)
      filename = if spec_name == "primary"
        schema_file_type(format)
      else
        "#{spec_name}_#{schema_file_type(format)}"
      end

      ENV["DATA_SCHEMA"] || File.join(db_dir, filename)
    end

    def check_schema_file(filename)
      unless File.exist?(filename)
        message = +%{#{filename} doesn't exist yet. Run `rake data:migrate` to create it, then try again.}
        Kernel.abort message
      end
    end

    def pending_migrations
      sort_migrations(
        pending_schema_migrations,
        pending_data_migrations
      )
    end

    def sort_migrations(*migrations)
      migrations.flatten.sort { |a, b| sort_string(a) <=> sort_string(b) }
    end

    def sort_string migration
      "#{migration[:version]}_#{migration[:kind] == :data ? 1 : 0}"
    end

    def data_migrations_path
      ::DataMigrate.config.data_migrations_path
    end

    def run_migration(migration, direction)
      if migration[:kind] == :data
        ::ActiveRecord::Migration.write("== %s %s" % ['Data', "=" * 71])
        ::DataMigrate::DataMigrator.run(direction, data_migrations_path, migration[:version])
      else
        ::ActiveRecord::Migration.write("== %s %s" % ['Schema', "=" * 69])
        ::DataMigrate::SchemaMigration.run(
          direction,
          ::DataMigrate::SchemaMigration.migrations_paths,
          migration[:version]
        )
      end
    end

    def schema_dump_path(db_config, format = ActiveRecord.schema_format)
      return ENV["DATA_SCHEMA"] if ENV["DATA_SCHEMA"]

      # We only require a schema.rb file for the primary database
      return unless db_config.primary?

      File.join(File.dirname(ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(db_config, format)), schema_file_type)
    end

    # Override this method from `ActiveRecord::Tasks::DatabaseTasks`
    # to ensure that the sha saved in ar_internal_metadata table
    # is from the original schema.rb file
    def schema_sha1(file)
      ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env, name: "primary"))
    end

    def forward(step = 1)
      DataMigrate::DataMigrator.create_data_schema_table
      migrations = pending_migrations.reverse.pop(step).reverse
      migrations.each do | pending_migration |
        if pending_migration[:kind] == :data
          ActiveRecord::Migration.write("== %s %s" % ["Data", "=" * 71])
          DataMigrate::DataMigrator.run(:up, data_migrations_path, pending_migration[:version])
        elsif pending_migration[:kind] == :schema
          ActiveRecord::Migration.write("== %s %s" % ["Schema", "=" * 69])
          DataMigrate::SchemaMigration.run(:up, DataMigrate::SchemaMigration.migrations_paths, pending_migration[:version])
        end
      end
    end

    def pending_data_migrations
      data_migrations = DataMigrate::DataMigrator.migrations(data_migrations_path)
      data_migrator = DataMigrate::RailsHelper.data_migrator(:up, data_migrations)
      sort_migrations(
        data_migrator.pending_migrations.map { |m| { version: m.version, name: m.name, kind: :data } }
      )
    end

    def pending_schema_migrations
      ::DataMigrate::SchemaMigration.pending_schema_migrations
    end

    def past_migrations(sort = nil)
      data_versions = DataMigrate::RailsHelper.data_schema_migration.table_exists? ? DataMigrate::RailsHelper.data_schema_migration.normalized_versions : []
      schema_versions = DataMigrate::RailsHelper.schema_migration.normalized_versions
      migrations = data_versions.map { |v| { version: v.to_i, kind: :data } } + schema_versions.map { |v| { version: v.to_i, kind: :schema } }

      sort&.downcase == "asc" ? sort_migrations(migrations) : sort_migrations(migrations).reverse
    end

    def self.migrate_with_data
      initialize_databases_for_migrate
      DataMigrate::DataMigrator.create_data_schema_table

      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true

      # 7.2 removes the param for db_configs_with_versions in https://github.com/rails/rails/commit/9572fcb4a0bd5396436689a6a42613886871cd81
      # 7.1 stable backported the change in https://github.com/rails/rails/commit/c53ec4b60980036b43528829d4b0b7457f759224
      schema_mapped_versions = if Gem::Dependency.new("railties", ">= 7.1.4").match?("railties", Gem.loaded_specs["railties"].version, true)
        ActiveRecord::Tasks::DatabaseTasks.db_configs_with_versions
      else
        db_configs = ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env)

        ActiveRecord::Tasks::DatabaseTasks.db_configs_with_versions(db_configs)
      end

      data_mapped_versions = DataMigrate::DatabaseTasks.db_configs_with_versions

      mapped_versions = schema_mapped_versions.merge(data_mapped_versions) do |_key, schema_db_configs, data_db_configs|
        schema_db_configs + data_db_configs
      end

      mapped_versions.sort.each do |version, db_configs|
        db_configs.each do |db_config|
          if is_data_migration = db_config.is_a?(DataMigrate::DatabaseConfigurationWrapper)
            db_config = db_config.db_config
          end

          DataMigrate::DatabaseTasks.with_temporary_connection(db_config) do
            if is_data_migration
              DataMigrate::DataMigrator.run(:up, DataMigrate::DatabaseTasks.data_migrations_path, version)
            else
              ActiveRecord::Tasks::DatabaseTasks.migrate(version)
            end
          end
        end
      end
    end

    # Sets up a blank primary database, as Rails does when db:prepare (7.1+)
    # or db:migrate (8.0+) runs on one: creates it if missing and, without
    # schema_migrations yet, loads schema.rb instead of running every migration
    # from the first. data_schema.rb is loaded after it: the data migrations it
    # records are marked as run, as the schema migrations are, instead of being
    # run on a schema they were not written for.
    # Returns whether the database was blank, to be seeded then.
    def self.initialize_database_with_data(db_config)
      with_temporary_pool(db_config) do
        begin
          initialized = DataMigrate::RailsHelper.schema_migration.table_exists?
        rescue ActiveRecord::NoDatabaseError
          create(db_config)
          retry
        end
        next false if initialized

        schema = ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(db_config)
        if schema && File.exist?(schema)
          ActiveRecord::Tasks::DatabaseTasks.load_schema(db_config)

          data_schema = schema_dump_path(db_config)
          if data_schema && File.exist?(data_schema)
            begin
              verbose_was, ActiveRecord::Migration.verbose = ActiveRecord::Migration.verbose, false
              load(data_schema)
            ensure
              ActiveRecord::Migration.verbose = verbose_was
            end
          end
        end

        true
      end
    end

    # Since Rails 8.0, db:migrate sets up a blank database once its first
    # migration is due. That is too late here: the data migrator that lists the
    # pending data migrations creates schema_migrations, after which the
    # database looks set up and every migration runs from the first. So
    # db:migrate:with_data sets it up before anything else.
    def self.initialize_databases_for_migrate
      return unless ActiveRecord::Tasks::DatabaseTasks.respond_to?(:initialize_database, true)

      ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each do |db_config|
        initialize_database_with_data(db_config) if primary?(db_config)
      end
    end

    def self.prepare_all_with_data
      seed = false

      each_current_configuration(env) do |db_config|
        next unless primary?(db_config)

        if DataMigrate::RailsHelper.rails_version_equal_to_or_higher_than_7_1
          # A database created or still blank is seeded, as db:prepare does.
          seed = true if initialize_database_with_data(db_config)
        else
          with_temporary_pool(db_config) do |pool|
            unless database_exists?(pool.connection)
              create(db_config)
              if File.exist?(schema_dump_path(db_config))
                load_schema(db_config, schema_format, nil)
                load_schema_current(
                  :ruby,
                  ENV["DATA_SCHEMA"]
                )
              end

              seed = true
            end
          end
        end

        with_temporary_pool(db_config) do |_pool|
          migrate_with_data
          if dump_schema_after_migration?
            dump_schema(db_config)
            DataMigrate::Tasks::DataMigrateTasks.dump
          end
        end
      end

      load_seed if seed
    end

    private

    def database_exists?(connection)
      if connection.respond_to?(:database_exists?)  # Rails 7.1+
        connection.database_exists?
      else
        connection.table_exists?(ActiveRecord::SchemaMigration.table_name)
      end
    rescue ActiveRecord::NoDatabaseError
      false
    end

    def primary?(db_config)
      if db_config.respond_to?(:primary?)  # Rails 7.0+
        db_config.primary?
      else
        db_config.name == "primary"
      end
    end

    def dump_schema_after_migration?
      if ActiveRecord.respond_to?(:dump_schema_after_migration)
        ActiveRecord.dump_schema_after_migration
      else
        ActiveRecord::Base.dump_schema_after_migration
      end
    end

    def schema_format
      if ActiveRecord.respond_to?(:schema_format)
        ActiveRecord.schema_format
      else
        ActiveRecord::Base.schema_format
      end
    end
  end
end
