# frozen_string_literal: true

require "data_migrate/config"

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    class << self
      def schema_file(_format = nil)
        File.join(db_dir, "data_schema.rb")
      end

      def schema_file_type(_format = nil)
        "data_schema.rb"
      end

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
        migrations.flatten.sort { |a, b|  sort_string(a) <=> sort_string(b) }
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

      # This method only exists in Rails 7.0+.
      if method_defined?(:schema_dump_path)
        alias_method :original_schema_dump_path, :schema_dump_path
      end

      def schema_dump_path(db_config, format = ActiveRecord.schema_format)
        return ENV["DATA_SCHEMA"] if ENV["DATA_SCHEMA"]

        # We only require a schema.rb file for the primary database
        return unless db_config.primary?

        schema_to_data_schema_dump_paths.fetch(super)
      end

      # Override this method from `ActiveRecord::Tasks::DatabaseTasks`
      # to ensure that the sha saved in ar_internal_metadata table
      # is from the original schema.rb file
      def schema_sha1(file)
        super(schema_to_data_schema_dump_paths.key(file))
      end

      private

      def schema_to_data_schema_dump_paths
        @schema_to_data_schema_dump_paths ||= begin
          ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each_with_object({}) do |db_config, mapping|
            dump_path = respond_to?(:original_schema_dump_path) ? original_schema_dump_path(db_config) : ActiveRecord::Tasks::DatabaseTasks.dump_filename(db_config.name)
            # As of Rails 7.0, `schema_dump` could return false for when schema dumping is not supported.
            next unless dump_path

            data_dump_name = File.basename(dump_path, File.extname(dump_path))

            unless data_dump_name.gsub!(/(_)?(schema|structure)\z/, "\\1#{schema_file_type}")
              data_dump_name.concat("_#{schema_file_type}")
            end

            mapping[dump_path] = File.join(File.dirname(dump_path), data_dump_name)
          end
        end
        puts @schema_to_data_schema_dump_paths.inspect
        @schema_to_data_schema_dump_paths
      end
    end

    def self.forward(step = 1)
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

    def self.pending_data_migrations
      data_migrations = DataMigrate::DataMigrator.migrations(data_migrations_path)
      data_migrator = DataMigrate::RailsHelper.data_migrator(:up, data_migrations)
      sort_migrations(
        data_migrator.pending_migrations.map { |m| { version: m.version, name: m.name, kind: :data } }
        )
    end

    def self.pending_schema_migrations
      ::DataMigrate::SchemaMigration.pending_schema_migrations
    end

    def self.past_migrations(sort = nil)
      data_versions = DataMigrate::RailsHelper.data_schema_migration.table_exists? ? DataMigrate::RailsHelper.data_schema_migration.normalized_versions : []
      schema_versions = DataMigrate::RailsHelper.schema_migration.normalized_versions
      migrations = data_versions.map { |v| { version: v.to_i, kind: :data } } + schema_versions.map { |v| { version: v.to_i, kind: :schema } }

      sort&.downcase == "asc" ? sort_migrations(migrations) : sort_migrations(migrations).reverse
    end
  end
end
