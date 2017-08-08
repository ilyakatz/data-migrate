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

      def assure_data_schema_table
        ActiveRecord::Base.establish_connection(db_config)
        sm_table = DataMigrate::DataMigrator.schema_migrations_table_name

        unless table_exists?(ActiveRecord::Base.connection, sm_table)
          create_table(sm_table)
        end
      end

      def status
        config = ActiveRecord::Base.configurations[Rails.env || 'development']
        ActiveRecord::Base.establish_connection(config)

        unless ActiveRecord::Base.connection.table_exists?(DataMigrate::DataMigrator.schema_migrations_table_name)
          puts 'Data migrations table does not exist yet. Creating ....'
          assure_data_schema_table
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
end
