require 'active_record'

module DataMigrate

  class DataMigrator < ActiveRecord::Migrator

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        DataMigrate::DataSchemaMigration.where(:version => version.to_s).delete_all
      else
        migrated << version
        DataMigrate::DataSchemaMigration.create!(:version => version.to_s)
      end
    end

    class << self
      def get_all_versions(connection = ActiveRecord::Base.connection)
        if table_exists?(connection, schema_migrations_table_name)
          # Certain versions of the gem wrote data migration versions into
          # schema_migrations table. After the fix, it was corrected to write into
          # data_migrations. However, not to break anything we are going to
          # get versions from both tables.
          #
          # This may cause some problems:
          # Eg. rake data:versions will show version from the schema_migrations table
          # which may be a version of actual schema migration and not data migration
          DataMigrate::DataSchemaMigration.all.map { |x| x.version.to_i }.sort +
            ActiveRecord::SchemaMigration.all.map { |x| x.version.to_i }.sort
        else
          []
        end
      end

      def schema_migrations_table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def migrations_path
        'db/data'
      end

      ##
      # Provides the full migrations_path filepath
      # @return (String)
      def full_migrations_path
        File.join(Rails.root, *migrations_path.split(File::SEPARATOR))
      end

      def assure_data_schema_table
        ActiveRecord::Base.establish_connection(db_config)
        sm_table = DataMigrate::DataMigrator.schema_migrations_table_name

        unless table_exists?(ActiveRecord::Base.connection, sm_table)
          create_table(sm_table)
        end
      end

      ##
      # Compares the given filename with what we expect data migration filenames to be, eg
      # the "20091231235959_some_name.rb" pattern
      # @param (String) filename
      # @return (MatchData)
      def match(filename)
        /(\d{14})_(.+)\.rb/.match(filename)
      end

      private

      def create_table(sm_table)
        ActiveRecord::Base.connection.create_table(sm_table, :id => false) do |schema_migrations_table|
            schema_migrations_table.column :version, :string, :null => false
          end

          suffix = ActiveRecord::Base.table_name_suffix
          prefix = ActiveRecord::Base.table_name_prefix
          index_name = "#{prefix}unique_data_migrations#{suffix}"

          ActiveRecord::Base.connection.add_index sm_table, :version,
            :unique => true,
            :name => index_name
      end

      def table_exists?(connection, table_name)
        # Avoid the warning that table_exists? prints in Rails 5.0 due a change in behavior between
        # Rails 5.0 and Rails 5.1 of this method with respect to database views.
        if ActiveRecord.version >= Gem::Version.new('5.0') && ActiveRecord.version < Gem::Version.new('5.1')
          connection.data_source_exists?(table_name)
        else
          connection.table_exists?(schema_migrations_table_name)
        end
      end

      def db_config
        ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV["DATABASE_URL"]
      end

    end
  end

  ##
  # This class extends DatabaseTasks to override the schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    def self.schema_file(format = ActiveRecord::Base.schema_format)
      case format
      when :ruby
        File.join(db_dir, "data_schema.rb")
      else
        message = "Only Ruby-based data_schema files are supported at this time."
        Kernel.abort message
      end
    end
  end

  ##
  # Provides the definition method for data_schema.rb
  class Data < ActiveRecord::Schema
    # This method is based on the following two methods
    #   ActiveRecord::Schema#define
    #   ActiveRecord::ConnectionAdapters::SchemaStatements#ssume_migrated_upto_version
    def define(info)
      DataMigrate::DataMigrator.assure_data_schema_table

      return if info[:version].blank?

      version = info[:version].to_i
      sm_table = quote_table_name(DataMigrate::DataMigrator.schema_migrations_table_name)
      migrated = select_values("SELECT version FROM #{sm_table}").map(&:to_i)

      versions = []
      Dir.foreach(DataMigrate::DataMigrator.full_migrations_path) do |file|
        match_data = DataMigrate::DataMigrator.match(file)
        versions << match_data[1].to_i if match_data
      end

      unless migrated.include?(version)
        execute "INSERT INTO #{sm_table} (version) VALUES ('#{version}')"
      end

      inserted = Set.new
      (versions - migrated).each do |v|
        if inserted.include?(v)
          raise "Duplicate data migration #{v}. Please renumber your data migrations to resolve the conflict."
        elsif v < version
          execute "INSERT INTO #{sm_table} (version) VALUES ('#{v}')"
          inserted << v
        end
      end
    end
  end

  ##
  # Provides the capability to write the current data schema version to the data_schema file
  # Based on ActiveRecord::SchemaDumper
  class SchemaDumper
    private_class_method :new

    class << self
      def dump(connection = ActiveRecord::Base.connection, stream = STDOUT)
        new(connection).dump(stream)
        stream
      end
    end

    def dump(stream)
      define_params = @version ? "version: #{@version}" : ""

      if stream.respond_to?(:external_encoding) && stream.external_encoding
        stream.puts "# encoding: #{stream.external_encoding.name}"
      end

      stream.puts "DataMigrate::Data.define(#{define_params})"

      stream
    end

    private

      def initialize(connection)
        @connection = connection
        @version = DataMigrate::DataSchemaMigration.all.map { |x| x.version.to_i }.max rescue 0
      end
  end
end
