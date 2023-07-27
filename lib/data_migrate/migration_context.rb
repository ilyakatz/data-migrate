module DataMigrate
  class MigrationContext < ActiveRecord::MigrationContext
    def initialize(migrations_paths = "db/data")
      @migrations_paths = migrations_paths || "db/data"
    end

    def up(target_version = nil)
      selected_migrations = if block_given?
                              migrations.select { |m| yield m }
                            else
                              migrations
                            end

      data_migrator = DataMigrate::RailsHelper.data_migrator(:up, selected_migrations, DataMigrate::RailsHelper.schema_migration, DataMigrate::RailsHelper.internal_metadata, target_version)
      data_migrator.migrate
    end

    def down(target_version = nil)
      selected_migrations =
        if block_given?
          migrations.select { |m| yield m }
        else
          migrations
        end

      data_migrator = DataMigrate::RailsHelper.data_migrator(:down, selected_migrations, DataMigrate::RailsHelper.schema_migration, DataMigrate::RailsHelper.internal_metadata, target_version)
      data_migrator.migrate
    end

    def run(direction, target_version)
      data_migrator = DataMigrate::RailsHelper.data_migrator(direction, migrations, DataMigrate::RailsHelper.schema_migration, DataMigrate::RailsHelper.internal_metadata, target_version)
      data_migrator.run
    end

    def current_version
      get_all_versions.max || 0
    rescue ActiveRecord::NoDatabaseError
    end

    def migration_files
      paths = Array(migrations_paths)
      Dir[*paths.flat_map { |path| "#{path}/**/[0-9]*_*.rb" }]
    end

    def migrations_status
      db_list = DataMigrate::RailsHelper.data_schema_migration.normalized_versions

      file_list = migration_files.map do |file|
        version, name, scope = parse_migration_filename(file)
        raise ActiveRecord::IllegalMigrationNameError.new(file) unless version
        version = DataMigrate::RailsHelper.schema_migration.normalize_migration_number(version)
        status = db_list.delete(version) ? "up" : "down"
        [status, version, (name + scope).humanize]
      end.compact

      db_list.map! do |version|
        ["up", version, "********** NO FILE **********"]
      end

      (db_list + file_list).sort_by { |_, version, _| version }
    end

    private

    def get_all_versions
      if DataMigrate::RailsHelper.data_schema_migration.table_exists?
        DataMigrate::RailsHelper.data_schema_migration.normalized_versions.map(&:to_i)
      else
        []
      end
    end

    def move(direction, steps)
      migrator = DataMigrate::RailsHelper.data_migrator(direction, migrations)

      if current_version != 0 && !migrator.current_migration
        raise ActiveRecord::UnknownMigrationVersionError.new(current_version)
      end

      start_index =
        if current_version.zero?
          0
        else
          migrator.migrations.index(migrator.current_migration)
        end

      finish = migrator.migrations[start_index + steps]
      version = finish ? finish.version : 0
      send(direction, version)
    end

  end
end
